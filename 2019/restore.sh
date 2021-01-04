#!/bin/bash
set -eo pipefail

export SQLCMDPASSWORD=${SA_PASSWORD:-$(<${SA_PASSWORD_FILE})}

# Check for either ENV variable or CLI-supplied argument
if [ -z "${MSSQL_DATABASE}" -a -z "$1" ]; then
  echo >&2 "No Database Target Specified for restore.  Supply either MSSQL_DATABASE environment variable or database as first argument."
  exit 1
fi

# Set Targets
DATABASE_TARGET=${1:-${MSSQL_DATABASE}} # Prioritize first argument, fall back to env variable
BACKUP_TARGET=/backups
LATEST_BACKUP_FILE=$(ls -Art "${BACKUP_TARGET}" | tail -n 1)
BACKUP_FILE_NAME=${2:-$LATEST_BACKUP_FILE} # Prioritize param, fallback to latest

BACKUP_TO_RESTORE="${BACKUP_TARGET}/${BACKUP_FILE_NAME}"

# Perform Database Restore
echo "Initiating restore of database [${DATABASE_TARGET}] from ${BACKUP_TO_RESTORE}"
/opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa \
  -Q "ALTER DATABASE [${DATABASE_TARGET}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
/opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa \
  -Q "RESTORE DATABASE [${DATABASE_TARGET}] FROM DISK = N'${BACKUP_TO_RESTORE}' WITH REPLACE;"
