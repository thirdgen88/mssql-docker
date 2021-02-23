FROM mcr.microsoft.com/mssql-tools:latest
LABEL maintainer="mierzwid"

RUN apt-get update && \
    apt-get install -y nano awscli cron

COPY ./scripts /

RUN chmod +x /*.sh

# to match uid & gid from the MS SQL image and share volume between containers
RUN adduser --disabled-password --gecos "user to share backups" --gid 0 --uid 10001 mssql
RUN mkdir /backups && \
    chown mssql:root /backups

ENTRYPOINT ["/entrypoint.sh"]