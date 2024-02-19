#!/bin/bash
set -eo pipefail
shopt -s nullglob

sqlcmd=( sqlcmd -S localhost -U sa -l 3 -V 16)

restore_backup() {
  local backup_file="$1"
  local database_name
  database_name=$(basename "$backup_file" .bak)

  export BACKUP_FILE="${backup_file}"
  export DATABASE_NAME="${database_name}"
	envsubst < /opt/mssql/etc/restore.sql > /var/opt/mssql/restore.sql
  unset BACKUP_FILE
  unset DATABASE_NAME
    
  # "${sqlcmd[@]}" -i /var/opt/mssql/restore.sql
}

restore_backup "$@"