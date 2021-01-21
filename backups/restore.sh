#!/bin/bash
set -eo pipefail

export SQLCMDPASSWORD=${SA_PASSWORD:-$(<${SA_PASSWORD_FILE})}

BACKUP_LABEL=$2

# Check for either ENV variable or CLI-supplied argument
if [ -z "${MSSQL_DATABASE}" -a -z "$1" ]; then
  echo >&2 "No Database Target Specified for restore.  Supply either MSSQL_DATABASE environment variable or database as first argument."
  exit 1
fi

# Set Targets
DATABASE_TARGET=${1:-${MSSQL_DATABASE}} # Prioritize first argument, fall back to env variable
BACKUP_TARGET=/backups
LATEST_BACKUP_FILE=$(find $BACKUP_TARGET | sort | tail -n 1)

if [ -z "$BACKUP_LABEL" ]; then
  BACKUP_TO_RESTORE=$LATEST_BACKUP_FILE
else
  BACKUP_TO_RESTORE=$(find $BACKUP_TARGET/*${BACKUP_LABEL} | sort | tail -n 1)
fi

# Perform Database Restore
echo "Initiating restore of database [${DATABASE_TARGET}] from ${BACKUP_TO_RESTORE}"
/opt/mssql-tools/bin/sqlcmd \
  -S "$MSSQL_HOSTNAME" -U sa \
  -Q "ALTER DATABASE [${DATABASE_TARGET}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      RESTORE DATABASE [${DATABASE_TARGET}] FROM DISK = N'${BACKUP_TO_RESTORE}' WITH REPLACE;
      ALTER DATABASE [${DATABASE_TARGET}] SET MULTI_USER WITH ROLLBACK IMMEDIATE;"
