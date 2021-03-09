#!/bin/bash
set -eo pipefail

export SQLCMDPASSWORD=${SA_PASSWORD:-$(<${SA_PASSWORD_FILE})}

BACKUP_LABEL=$2

# Check for either ENV variable or CLI-supplied argument
if [ -z "${MSSQL_DATABASE}" -a -z "$1" ]; then
  echo >&2 "No Database Target specified for restore. Please supply either MSSQL_DATABASE environment variable or database as first argument."
  exit 1
fi
if [ -z "${SA_PASSWORD_FILE}" ]; then
  echo >&2 "No Database password file specified for restore. Please supply SA_PASSWORD_FILE environment variable."
  exit 1
fi
if [ -z "${MSSQL_USER}" ]; then
  echo >&2 "No Database User specified for restore. Please supply MSSQL_USER environment variable."
  exit 1
fi
if [ -z "$MSSQL_HOSTNAME" ]; then
  echo "Please pass MS SQL hostname as environment variable 'MSSQL_HOSTNAME'"
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
echo
/opt/mssql-tools/bin/sqlcmd \
  -S "$MSSQL_HOSTNAME" -U sa \
  -Q "ALTER DATABASE [${DATABASE_TARGET}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      RESTORE DATABASE [${DATABASE_TARGET}] FROM DISK = N'${BACKUP_TO_RESTORE}' WITH REPLACE;
      ALTER DATABASE [${DATABASE_TARGET}] SET MULTI_USER WITH ROLLBACK IMMEDIATE;"

RESTORE_RESULT=$?

if [ $RESTORE_RESULT -ne 0 ]; then
  echo "RESTORE: Restore procedure failed!"
  echo
  exit 1
fi

echo "Updating [${DATABASE_TARGET}] DB owner to [${MSSQL_USER}]"
echo "ALTER AUTHORIZATION ON DATABASE::${DATABASE_TARGET} TO ${MSSQL_USER};"
echo

/opt/mssql-tools/bin/sqlcmd \
  -S "$MSSQL_HOSTNAME" -U sa \
  -Q "ALTER AUTHORIZATION ON DATABASE::${DATABASE_TARGET} TO ${MSSQL_USER};"

USER_CHANGE_RESULT=$?

if [ $USER_CHANGE_RESULT -ne 0 ]; then
  echo "RESTORE: Failed to change the user!"
  echo
  exit 1
fi
