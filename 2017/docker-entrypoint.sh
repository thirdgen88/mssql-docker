#!/bin/bash
set -eo pipefail
shopt -s nullglob

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# usage: process_init_file FILENAME SQLCMD...
#    ie: process_init_file foo.sh sqlcmd -S localhost -u sa
# (process a single initializer file, based on its extension. we define this
# function here, so that initializer scripts (*.sh) can use the same logic,
# potentially recursively, or override the logic used in subsequent calls)
process_init_file() {
	local f="$1"; shift
	local sqlcmd=( "$@" )

	case "$f" in
		*.sh)     echo "$0: running $f"; . "$f" ;;
		*.sql)    echo "$0: running $f"; "${sqlcmd[@]}" -i "$f"; echo ;;
        *.bak)    echo "$0: restoring $f"; "${sqlcmd[@]}" -Q "RESTORE DATABASE [$(basename ${f/.bak/})] FROM DISK='$f'"; echo ;;
		*)        echo "$0: ignoring $f" ;;
	esac
	echo
}

MSSQL_BASE=${MSSQL_BASE:-/var/opt/mssql}
MSSQL_PROVISIONING_FILE_TEMPLATE=${MSSQL_BASE}/setup.sql
MSSQL_PROVISIONING_FILE=${MSSQL_BASE}/setup-temp.sql

# Collect SQL Product Edition
file_env 'MSSQL_PID' 'Developer'

# Check for Init Complete
if [ ! -f "${MSSQL_BASE}/.docker-init-complete" ]; then
    # Mark Initialization Complete
    mkdir -p ${MSSQL_BASE}
    touch ${MSSQL_BASE}/.docker-init-complete

    # Check some critical environment variables
    file_env 'SA_PASSWORD'
    if [ -z "${SA_PASSWORD}" -a -z "${MSSQL_RANDOM_SA_PASSWORD}" ]; then
        echo >&2 "ERROR: Database initialization aborted, you must specify either SA_PASSWORD or MSSQL_RANDOM_SA_PASSWORD"
        exit 1
    else
		if [ ! -z "$MSSQL_RANDOM_SA_PASSWORD" ]; then
			export SA_PASSWORD="$(pwgen -1 32)"
			echo "GENERATED SA PASSWORD: $SA_PASSWORD"
		fi
        export SQLCMDPASSWORD=$SA_PASSWORD
    fi

    # Initialize MSSQL before attempting database creation
    "$@" &
    pid="$!"

    # Wait up to 60 seconds for database initialization to complete
    echo "Database Startup In Progress..."
    for ((i=${MSSQL_STARTUP_DELAY:=60};i>0;i--)); do
        if /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -l 1 -t 1 -V 16 -Q "SELECT 1" &> /dev/null; then
            echo "Database healthy, proceeding with provisioning..."
            break
        fi
        sleep 1
    done
    if [ "$i" -le 0 ]; then
        echo >&2 "Database initialization process failed after ${MSSQL_STARTUP_DELAY} delay."
        exit 1
    fi

    # Run the provisioning action
    file_env 'MSSQL_DATABASE'
    file_env 'MSSQL_USER'
    file_env 'MSSQL_PASSWORD'
    if [ "${MSSQL_DATABASE}" -a "${MSSQL_USER}" -a "${MSSQL_PASSWORD}" ]; then
        envsubst < "${MSSQL_PROVISIONING_FILE_TEMPLATE}" > "${MSSQL_PROVISIONING_FILE}"
        /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -b -m 16 -V 16 -i ${MSSQL_PROVISIONING_FILE}
        if [ $? -eq 0 ]; then
            echo "Provisioning completed, database [${MSSQL_DATABASE}] created."
            rm ${MSSQL_PROVISIONING_FILE}
        else
            echo >&2 "Failed to provision database."
            exit 1
        fi
    else
        echo "Provisioning parameters not specified, skipping..."
    fi

    # Set SQLCMD command string for additional initialization file processing
    sqlcmd=( sqlcmd -S localhost -U sa -l 3 -t 3 -V 16 )

    echo
    ls /docker-entrypoint-initdb.d/ > /dev/null
    for f in /docker-entrypoint-initdb.d/*; do
        process_init_file "$f" "${sqlcmd[@]}"
    done

    echo "Startup Complete."

    # Attach and wait for exit
    wait "$pid"
else
    exec "$@"
fi

