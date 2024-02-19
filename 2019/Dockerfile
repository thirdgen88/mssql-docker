ARG MSSQL_UPSTREAM_TAG=2019-GA-ubuntu-16.04
FROM mcr.microsoft.com/mssql/server:${MSSQL_UPSTREAM_TAG}
LABEL maintainer "Kevin Collins <kcollins@purelinux.net>"

# Install some additional prerequisites
USER root
RUN apt-get update && \
    apt-get install -y gettext pwgen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy in scripts
COPY docker-entrypoint.sh /
COPY setup.sql /var/opt/mssql/
COPY healthcheck.sh /
COPY backup.sh /

# Set a Simple Health Check
HEALTHCHECK \
    --interval=30s \
    --retries=3 \
    --start-period=10s \
    --timeout=30s \
    CMD /healthcheck.sh

# Put CLI tools on the PATH
ENV PATH /opt/mssql-tools/bin:$PATH

# Create some base paths and place our provisioning script
RUN mkdir /docker-entrypoint-initdb.d && \
    chown mssql:root /docker-entrypoint-initdb.d && \
    mkdir /backups && \
    chown mssql:root /backups && \
    mkdir -p /var/opt/mssql

# Return to mssql user
USER mssql

# Run SQL Server process.
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/opt/mssql/bin/sqlservr" ]