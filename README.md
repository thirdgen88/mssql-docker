# MSSQL for Linux under Docker with Extras 😎

[![Build Status](https://travis-ci.com/thirdgen88/mssql-docker.svg?branch=master)](https://travis-ci.com/thirdgen88/mssql-docker)
[![Docker Stars](https://img.shields.io/docker/stars/kcollins/mssql.svg)](https://hub.docker.com/r/kcollins/mssql)
[![Docker Pulls](https://img.shields.io/docker/pulls/kcollins/mssql.svg)](https://hub.docker.com/r/kcollins/mssql)

This is the Git repository for the [kcollins/mssql](http://hub.docker.com/r/kcollins/mssql) Docker Hub image. It
includes a `docker-compose.yml` file for easy use within a Docker Compose or Swarm configuration. See
the [Docker Hub page](http://hub.docker.com/r/kcollins/mssql) for more information on how to use this image.

Table of Contents
=================

* [Supported tags and respective Dockerfile links](#supported-tags-and-respective-dockerfile-links)
* [Quick Reference](#quick-reference)
* [Overview](#overview)
* [Getting Started](#getting-started)
    * [Starting up with a new empty database](#starting-up-with-a-new-empty-database)
    * [Generating a random SA password](#generating-a-random-sa-password)
* [Using Docker Compose](#using-docker-compose)
    * [Running the Docker Compose Service](#running-the-docker-compose-service)
* [Backing up your database](#backing-up-your-database)
* [Environment Variable Reference](#environment-variable-reference)
* [Dedicated backup container](#dedicated-backup-container)
* [References](#references)
* [License](#license)


# Supported tags and respective `Dockerfile` links

* [`2017`, `2017-latest-ubuntu` (2017/Dockerfile)](https://github.com/thirdgen88/mssql-docker/blob/master/2017/Dockerfile)
* [`2019`, `2019-latest`, `latest` (2019/Dockerfile)](https://github.com/thirdgen88/mssql-docker/blob/master/2019/Dockerfile)
* []

# Quick Reference

* **Where to file issues**:
  https://github.com/thirdgen88/mssql-docker/issues

* **Upstream Image**:
  mssql-hub

* **Maintained by**:
  Kevin Collins

* **Supported architectures**:
  `amd64`

* **Source of this description**:
  https://github.com/thirdgen88/mssql-docker/tree/master/docs ([History](https://github.com/thirdgen88/mssql-docker/commits/master/docs))

# Overview

This Docker image builds on the base [Microsoft SQL Server Linux Image][mssql-hub] and adds a lot of initial
provisioning functionality such as automated database backup restores, initial SQL script execution, easy DB backups,
all in a fairly easy to use setup.

# Getting Started

In order to run this image, you can follow the guidance listed in the [How to use this Image][mssql-hub] section of the
Microsoft Docker Hub Page. There are some additional environment variables exposed by the
custom [entrypoint](https://github.com/thirdgen88/mssql-docker/blob/master/2017/docker-entrypoint.sh) script that enable
some enhanced functionality. We'll take a look at some of those extended use-cases in this section.

## Starting up with a new empty database

To start a container named `sql1` with a new empty database named `test`, use the following:

    $ docker run -d -p 1433:1433 -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=ch@nge_m3" \
      -e "MSSQL_DATABASE=test" -e "MSSQL_USER=testuser" -e "MSSQL_PASSWORD=testpass" \
      --name sql1 kcollins/mssql:latest

## Generating a random SA password

You can also specify a random `sa` account password to be generated on startup and output to the console:

    $ docker run -d -p 1433:1433 -e "ACCEPT_EULA=Y" -e "MSSQL_RANDOM_SA_PASSWORD=Y" \
      --name sql1 kcollins/mssql:latest

# Using Docker Compose

There is an example Docker Compose configuration that demonstrates all of the advanced features that this image has to
offer. Let's take a look at a trimmed down version (click the [link][docker-compose] for the full file):

```yaml
version: '3.1'
services:
  db:
    image: kcollins/mssql:latest
    ports:
      - 1433:1433
    volumes:
      - db_data:/var/opt/mssql
      - ./db-backups:/backups
      - ./db-init:/docker-entrypoint-initdb.d
    secrets:
      - sa-password
      - mssql-password
    environment:
      # ACCEPT_EULA confirms your acceptance of the End-User Licensing Agreement.
      ACCEPT_EULA: Y
      SA_PASSWORD_FILE: /run/secrets/sa-password
      MSSQL_DATABASE: test
      MSSQL_USER: testuser
      MSSQL_PASSWORD_FILE: /run/secrets/mssql-password
      MSSQL_PID: Developer  # Change to the edition you need, e.g. "Express", "Standard", etc.

secrets:
  sa-password:
    file: ./secrets/SA_PASSWORD
  mssql-password:
    file: ./secrets/MSSQL_PASSWORD

volumes:
  db_data:
```

The definition above has a few notable features:

- The secrets functionality more closely mirrors what can be used with a Docker Swarm implementation. All you need to do
  is create files such as `./secrets/SA_PASSWORD` containing a single line with the desired password.
  The `SA_PASSWORD_FILE` environment variable contains the path to the secret file and will automatically be read and
  processed by the entrypoint script, ensuring that your passwords are not directly visible in environment variables
  within the container.

- The `db-init` bind-mount in the container allows you to place `.sql` or `.bak` files that will be processed on
  first-launch of the container. Keep in mind that a `my_db.bak` file will be restored as database `[my_db]`, so pay
  attention to the `.bak` names you place here. Any valid T-SQL files with a `.sql` extension will also be processed.

- You can define a named volume against `/var/opt/mssql` in order to persist your data, per the [base guidance] from
  Microsoft.

## Running the Docker Compose Service

Before you run under Docker Compose, lets make sure that you've created some prerequisite structures that won't be
pre-existing in the GitHub repository:

    $ mkdir db-backups && mkdir db-init && mkdir secrets
    $ echo ch@nge_m3 > secrets/SA_PASSWORD
    $ echo testpass > secrets/MSSQL_PASSWORD

The above commands will create the necessary folders and preload the secrets files with passwords. Feel free to change
the password you place in those files based on your needs.

To bring up the Docker Compose service, use the following command to launch in detached mode and then view the logs:

    $ docker-compose up -d && docker-compose logs -f

You can `Ctrl-C` safely out of the log view without shutting down your container. If you wish to shut it down your
container/service:

    $ docker-compose down

Note that at this point, your data is still preserved in a named volume. If you wish to remove volumes as well during
shutdown use the `-v` option.  **USE WITH CAUTION**

# Backing up your database

This image has built-in support for quick and easy backups. Let's assume you have a bind-mount back to your host for the
backup folder, such as what you would have with the `docker run` below:

    $ docker run -d -p 1433:1433 -e "ACCEPT_EULA=Y" -e "MSSQL_RANDOM_SA_PASSWORD=Y" \
      -e "MSSQL_DATABASE=my_database" -e "MSSQL_USER=user1" -e "MSSQL_PASSWORD=testpass" \
      -v ${PWD}/db-backups:/backups --name sql1 kcollins/mssql:latest

At this point, you can take a backup from your host with a simple `docker exec` statement:

    $ docker exec sql1 /backup.sh

You can also specify the database to be backed up:

    $ docker exec sql1 /backup.sh my_database

In your `./db-backups` folder, you'll have a nicely named file such as `my_database_20190120_044511.bak`. You can
specify a `RETAIN_FILES_COUNT=n` environment variable, where _n_ is the number of backup files to retain in
the `/backups` folder in the container. This can be helpful if you setup a cron task to periodically call
the `backup.sh` script on a schedule.

# Environment Variable Reference

Like described in some of the examples above, you can customize the start-up behavior of database container by
specifying the following additional environment variables (see also the built-in ones from
the [base image](https://hub.docker.com/r/microsoft/mssql-server)):

_Table 1 - Environment Variables_

Variable                           | Default | Description                                                            |
---------------------------------- | ------- | ---------------------------------------------------------------------- |
`MSSQL_DATABASE`                   |         | Name of database to be created on initial startup                      |
`MSSQL_USER`                       |         | Username that will be created and given `db_owner` to _MSSQL_DATABASE_ |
`MSSQL_PASSWORD`                   |         | Password for the _MSSQL_USER_                                          |
`MSSQL_STARTUP_DELAY`              | `60`    | Duration in seconds to wait for initial startup provisioning           |

Note that the `MSSQL_USER` and `MSSQL_PASSWORD` variables can also be specified with a `_FILE` suffix if the variable
contains a path to a file in the container with a single line value for the variable. This is helpful when used in
conjunction with [Docker Secrets](https://docs.docker.com/engine/reference/commandline/secret/).

In order to have the image provision a new empty database, you must specify all of `MSSQL_DATABASE`, `MSSQL_USER`,
and `MSSQL_PASSWORD`.

# Dedicated backup container

As an addition to extended MS SQL image, there is a dedicated backup image that can be used together with the MS SQL
image to perform maintenance tasks:

1. backups
    * on-demand using: /backup.sh script: `/backup.sh database-name`
    * on-demand adding label (defaults to `latest`) to a backup file: `/backup.sh database-name label`
2. uploading backups to
   a [S3 bucket configured via env variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html):
    * AWS_CONFIG_FILE - path to the AWS-CLI configuration file
    * AWS_SHARED_CREDENTIALS_FILE - path to the AWS-CLI credentials file
    * AWS_S3_SSE_CUSTOMER_KEY - path to the customer key for SSE encryption of backups
    * AWS_S3_BUCKET_NAME - S3 bucket name
3. periodical backups scheduled using cron:
    * ENABLE_PERIODIC_BACKUPS - set this variable to enable periodic backups - disabled by default
    * BACKUPS_CRON_SCHEDULE - configure schedule used by cron to run the backup task, defaults to `0 0 * * *` (every day
      at midnight)
4. restores
    * on-demand using: /restore.sh script - restores the latest backup
    * on-demand from the latest labeled backup, e.g.: `/restore.sh database-name 0.0.1` will restore the latest backup
      with `0.0.1`
      label; it is also supported to pass the full backup name instead of a label
5. restores directly from S3 bucket: `/restore-from-s3.sh database-name backup-name`

**Please notice:** In all enumerated cases `database-name` can be omitted (if used as the last parameter) or passed as
empty string `/backup.sh "" label` (if used as middle parameter) and this will default to `MSSQL_DATABASE` variable.

Sample compose file with configured MS SQL Server and DB Backup container - tested against Docker Swarm: [docker-compose-db-backup.yml](docker-compose-db-backup.yml)

# References

There is a lot of useful information over at
the [Microsoft Docs](https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-docker?view=sql-server-2017)
page for working with the MSSQL Docker Image. Take a look at that for more detailed information about managing the
container and performing other administrative tasks.

# License

For licensing information, consult the following links:

* Microsoft SQL Server - See the [License Section][mssql-hub] at the bottom of the Microsoft Docker Hub page for details
  on the licensing terms of using this derived image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc
from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies
with any relevant licenses for all software contained within.

[docker-compose]: https://github.com/thirdgen88/mssql-docker/blob/master/docker-compose.yml "Docker Compose Example"

[mssql-hub]: https://hub.docker.com/_/microsoft-mssql-server