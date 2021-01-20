FROM mcr.microsoft.com/mssql-tools:latest
LABEL maintainer="mierzwid"

RUN apt-get update && \
    apt-get install -y nano awscli cron

COPY backup.sh /
COPY restore.sh /
COPY publish-backup-to-s3.sh /
COPY restore-from-s3.sh /
COPY backup-cron.sh /

RUN mkdir /backups

COPY backup-cron /etc/cron.d/backup-cron

RUN touch /var/log/cron.log

CMD [ "cron", "&&", "tail", "-f", "/var/log/cron.log" ]