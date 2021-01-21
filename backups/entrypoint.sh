#!/bin/bash

# Start the run once job.
CRON_SCHEDULE=${BACKUPS_CRON_SCHEDULE:-"0 0 * * *"}

echo "DB-BACKUPS: Scheduling periodic backups: $CRON_SCHEDULE"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

# Setup a cron schedule
echo "SHELL=/bin/bash
BASH_ENV=/container.env
$CRON_SCHEDULE /backup-periodically.sh >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron" > scheduler.txt

touch /var/log/cron.log

crontab scheduler.txt
cron

tail -f /var/log/cron.log
