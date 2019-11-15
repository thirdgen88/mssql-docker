#!/bin/bash

export SQLCMDPASSWORD=${SA_PASSWORD:-$(< ${SA_PASSWORD_FILE})}

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -l 3 -t 3 -V 16 -Q "SELECT 1"