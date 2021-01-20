#!/bin/bash
set -eo pipefail

if [ -z "$ENABLE_DAILY_BACKUPS" ]; then
  echo "BACKUPS: Daily backups are not enabled."
  exit 0
fi

echo "BACKUPS: Starting daily backup."

if /backup.sh; then
  echo "BACKUPS: Daily backup completed!"
  exit 0
else
  echo "BACKUPS: Daily backup failed!"
  exit 1
fi
