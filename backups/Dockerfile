FROM mcr.microsoft.com/mssql-tools:latest
LABEL maintainer="mierzwid"

RUN apt-get update && \
    apt-get install -y nano awscli cron

COPY backup.sh /
COPY backup-periodically.sh /
COPY restore.sh /
COPY publish-backup-to-s3.sh /
COPY restore-from-s3.sh /
COPY entrypoint.sh /

RUN chmod +x /backup.sh /backup-periodically.sh /restore.sh /publish-backup-to-s3.sh /restore-from-s3.sh /entrypoint.sh

# to match uid & gid from the MS SQL image and share volume between containers
RUN adduser --disabled-password --gecos "user to share backups" --gid 0 --uid 10001 mssql
RUN mkdir /backups && \
    chown mssql:root /backups

ENTRYPOINT ["/entrypoint.sh"]