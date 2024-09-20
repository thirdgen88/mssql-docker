#!/bin/bash
set -eo pipefail

export SQLCMDPASSWORD=${MSSQL_SA_PASSWORD:-$(< "${MSSQL_SA_PASSWORD_FILE}")}

# Check for either ENV variable or CLI-supplied argument
if [ -z "${MSSQL_DATABASE}" ] && [ -z "$1" ]; then
  echo >&2 "No Database Target Specified for backup.  Supply either MSSQL_DATABASE environment variable or database as first argument."
  exit 1
fi

# Set Targets
DATABASE_TARGET=${1:-${MSSQL_DATABASE}}  # Prioritize first argument, fall back to env variable
BACKUP_TARGET=/backups
BACKUP_FILE="${BACKUP_TARGET}/${DATABASE_TARGET}_$(date +%Y%m%d_%H%M%S).bak"

# Perform Database Backup
echo "Initating backup of database [${DATABASE_TARGET}] to ${BACKUP_FILE}"
sqlcmd \
  -S localhost -U sa -C \
  -Q "BACKUP DATABASE [${DATABASE_TARGET}] TO DISK = N'${BACKUP_FILE}' WITH NOFORMAT, NOINIT, NAME = '${DATABASE_TARGET}-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

chmod 640 "${BACKUP_FILE}"

if [ -z "${RETAIN_FILES_COUNT}" ]; then
  echo "RETAIN_FILES_COUNT not set, skipping rotation."
else
  find "${BACKUP_TARGET}" -maxdepth 1 -type f -name "*.bak" -printf '%T@ %p\n' | \
    sort -n | head -n -"${RETAIN_FILES_COUNT}" | awk '{print $2}' | xargs rm -vf
fi