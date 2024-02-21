#!/bin/bash
set -eo pipefail
shopt -s nullglob

# Global vars
MSSQL_BASE=${MSSQL_BASE:-/var/opt/mssql}
MSSQL_RESTORE_FILE_TEMPLATE=/opt/mssql/etc/restore.sql
MSSQL_PROVISIONING_FILE_TEMPLATE=/opt/mssql/etc/setup.sql
MSSQL_PROVISIONING_FILE=${MSSQL_BASE}/setup.sql

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
  
  # shellcheck disable=SC1090
  case "$f" in
      *.sh)     info "$0: running $f"; . "$f" ;;
      *.sql)    info "$0: running $f"; "${sqlcmd[@]}" -i "$f" ;;
      *.bak)    restore_backup "$f" ;;
      *)        info "$0: ignoring $f" ;;
  esac
}

# usage: restore_backup BACKUP_FILE
#    ie: restore_backup /backups/mydb.bak
# Restore a database backup file, where the basename of the supplied file will be
# the database name.  Files in the backup will be relocated to `/var/opt/mssql/data`.
restore_backup() {
  local backup_file="$1"
  local database_name
  database_name=$(basename "$backup_file" .bak)
  local template_output_file="/var/opt/mssql/restore.sql"

  export BACKUP_FILE="${backup_file}"
  export DATABASE_NAME="${database_name}"
	envsubst < "${MSSQL_RESTORE_FILE_TEMPLATE}" > "${template_output_file}"
  unset BACKUP_FILE
  unset DATABASE_NAME

  info "$0: restoring database '${database_name}' from '${backup_file}'"
  "${sqlcmd[@]}" -i "${template_output_file}"

  rm "${template_output_file}"
}

# usage: info <message...>
function info() {
  readarray -t message_arr <<< "${*}"
  for message_line in "${message_arr[@]}"; do
    printf "%s entrypoint  %s\n" "$(date +'%Y-%m-%d %H:%M:%S.%2N')" "${message_line}"
  done
}

# Collect SQL Product Edition
file_env 'MSSQL_PID' 'Developer'

# Set umask
umask 0007

# Check for Init Complete
if [ ! -f "${MSSQL_BASE}/.docker-init-complete" ]; then
  # Mark Initialization Complete
  mkdir -p "${MSSQL_BASE}"
  touch "${MSSQL_BASE}/.docker-init-complete"

  # Check some critical environment variables
  file_env 'MSSQL_SA_PASSWORD'
  if [ -z "${MSSQL_SA_PASSWORD}" ] && [ -z "${MSSQL_RANDOM_SA_PASSWORD}" ]; then
    echo >&2 "ERROR: Database initialization aborted, you must specify either MSSQL_SA_PASSWORD or MSSQL_RANDOM_SA_PASSWORD"
    exit 1
  else
  if [ -n "$MSSQL_RANDOM_SA_PASSWORD" ]; then
    MSSQL_SA_PASSWORD="$(pwgen -1 32)"
    export MSSQL_SA_PASSWORD
    info "GENERATED SA PASSWORD: $MSSQL_SA_PASSWORD"
  fi
    export SQLCMDPASSWORD=$MSSQL_SA_PASSWORD
  fi

  # Initialize MSSQL before attempting database creation
  "$@" &
  pid="$!"

  # Wait up to 60 seconds for database initialization to complete
  for ((i=${MSSQL_STARTUP_DELAY:=60};i>0;i--)); do
    if /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -l 1 -t 1 -b -Q "SELECT 1" &> /dev/null; then
      break
    fi
    sleep 1
  done
  if [ "$i" -le 0 ]; then
    echo >&2 "Database initialization process failed after ${MSSQL_STARTUP_DELAY} delay."
    exit 1
  fi

  # Set SQLCMD command string for additional initialization file processing
  sqlcmd=( sqlcmd -S localhost -U sa -l 3 -V 16 )

  echo
  for f in /docker-entrypoint-initdb.d/*.bak /docker-entrypoint-initdb.d/*.sh /docker-entrypoint-initdb.d/*.sql; do
    process_init_file "$f" "${sqlcmd[@]}"
  done

  # Run the provisioning action
  file_env 'MSSQL_DATABASE'
  file_env 'MSSQL_USER'
  file_env 'MSSQL_PASSWORD'
  if [ "${MSSQL_DATABASE}" ] && [ "${MSSQL_USER}" ] && [ "${MSSQL_PASSWORD}" ]; then
    info "Database healthy, proceeding with provisioning..."
    envsubst < "${MSSQL_PROVISIONING_FILE_TEMPLATE}" > "${MSSQL_PROVISIONING_FILE}"
    if /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -b -i "${MSSQL_PROVISIONING_FILE}"; then
      info "Provisioning completed, database [${MSSQL_DATABASE}] created."
      rm "${MSSQL_PROVISIONING_FILE}"
    else
      info >&2 "Failed to provision database."
      exit 1
    fi
  fi

  # Attach and wait for exit
  trap 'kill "${pid}"; wait "${pid}"' SIGINT SIGTERM
  wait "$pid"
else
  exec "$@"
fi
