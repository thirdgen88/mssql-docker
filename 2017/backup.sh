#!/bin/bash
set -eo pipefail

export SQLCMDPASSWORD=${SA_PASSWORD:-$(< ${SA_PASSWORD_FILE})}

# Check for either ENV variable or CLI-supplied argument
if [ -z "${MSSQL_DATABASE}" -a -z "$1" ]; then
    echo >&2 "No Database Target Specified for backup.  Supply either MSSQL_DATABASE environment variable or database as first argument."
    exit 1
fi

# Set Targets
DATABASE_TARGET=${1:-${MSSQL_DATABASE}}  # Prioritize first argument, fall back to env variable
BACKUP_TARGET=/backups
BACKUP_FILE="${BACKUP_TARGET}/${DATABASE_TARGET}_$(date +%Y%m%d_%H%M%S).bak"

# Perform Database Backup
echo "Initating backup of database [${DATABASE_TARGET}] to ${BACKUP_FILE}"
/opt/mssql-tools/bin/sqlcmd \
   -S localhost -U sa \
   -Q "BACKUP DATABASE [${DATABASE_TARGET}] TO DISK = N'${BACKUP_FILE}' WITH NOFORMAT, NOINIT, NAME = '${DATABASE_TARGET}-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

chmod 640 ${BACKUP_FILE}

if [ -z ${RETAIN_FILES_COUNT} ]; then
    echo "RETAIN_FILES_COUNT not set, skipping rotation."
else
    ls -1 ${BACKUP_TARGET}/*.bak | sort -r | tail -n +`expr ${RETAIN_FILES_COUNT} + 1` | xargs rm > /dev/null 2>&1
fi