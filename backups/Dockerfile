FROM mcr.microsoft.com/mssql-tools:latest
LABEL maintainer="mierzwid"

RUN apt-get update && \
    apt-get install -y nano awscli cron

COPY backup.sh /
COPY backup-daily.sh /
COPY restore.sh /
COPY publish-backup-to-s3.sh /
COPY restore-from-s3.sh /
COPY entrypoint.sh /

RUN chmod +x /backup.sh /backup-daily.sh /restore.sh /publish-backup-to-s3.sh /restore-from-s3.sh /entrypoint.sh

RUN mkdir /backups

ENTRYPOINT ["/entrypoint.sh"]