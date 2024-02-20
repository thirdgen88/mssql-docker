ARG MSSQL_UPSTREAM_TAG=2022-latest
FROM mcr.microsoft.com/mssql/server:${MSSQL_UPSTREAM_TAG}
LABEL maintainer "Kevin Collins <kcollins@purelinux.net>"

# Install some additional prerequisites
USER root
RUN apt-get update && \
    apt-get install -y gettext pwgen && \
    rm -rf /var/lib/apt/lists/*

# Copy in scripts
COPY docker-entrypoint.sh /usr/local/bin/
COPY --chmod=0664 --chown=1000:1000 setup.sql restore.sql /opt/mssql/etc/
COPY --chmod=0755 --chown=root:root \
    healthcheck.sh \
    backup.sh \
    /usr/local/bin/

# Set a Simple Health Check
HEALTHCHECK \
    --interval=15s \
    --retries=3 \
    --start-period=10s \
    --timeout=3s \
    CMD healthcheck.sh

# Put CLI tools on the PATH
ENV PATH /opt/mssql-tools/bin:$PATH

# Setup a dedicated user for SQL Server (if missing), also set permissions on volume base
ARG MSSQL_USERHOME=/home/mssql
ARG MSSQL_UID=10001
ARG MSSQL_GID=10001
RUN mkdir ${MSSQL_USERHOME} && \
    (getent group ${MSSQL_GID} > /dev/null 2>&1 || groupadd -r mssql -g ${MSSQL_GID}) && \
    (getent passwd ${MSSQL_UID} > /dev/null 2>&1 || useradd -r -d ${MSSQL_USERHOME} -u ${MSSQL_UID} -g ${MSSQL_GID} mssql) && \
    chown mssql:mssql ${MSSQL_USERHOME} && \
    umask 0007 && \ 
    # Main volume target
    mkdir -p /var/opt/mssql && \
    chown mssql:mssql /var/opt/mssql && \
    # Initialization folder
    mkdir /docker-entrypoint-initdb.d && \
    chown mssql:mssql /docker-entrypoint-initdb.d && \
    # Backup Folder
    mkdir /backups && \
    chown mssql:mssql /backups

# Return to mssql user
USER mssql

# Run SQL Server process.
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD [ "/opt/mssql/bin/sqlservr" ]
