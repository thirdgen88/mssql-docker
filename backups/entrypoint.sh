#!/bin/bash

# Start the run once job.
echo "DB-BACKUPS: Docker container has been started"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

# Setup a cron schedule
echo "SHELL=/bin/bash
BASH_ENV=/container.env
* * * * * /backup-daily.sh >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron" > scheduler.txt

touch /var/log/cron.log

crontab scheduler.txt
cron

tail -f /var/log/cron.log
