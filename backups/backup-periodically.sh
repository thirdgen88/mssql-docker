#!/bin/bash
set -eo pipefail

if [ -z "$ENABLE_PERIODIC_BACKUPS" ]; then
  echo "BACKUPS: Periodic backups are not enabled."
  exit 0
fi

echo "BACKUPS: Starting periodic backup."

if /backup.sh; then
  echo "BACKUPS: Periodic backup completed!"
  exit 0
else
  echo "BACKUPS: Periodic backup failed!"
  exit 1
fi
