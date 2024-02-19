-- Check to see if database exists (restored in provisioning stage)
-- and create if it does not
IF db_id(N'${MSSQL_DATABASE}') IS NULL
  CREATE DATABASE [${MSSQL_DATABASE}]
GO
USE [${MSSQL_DATABASE}]
GO
-- Create Server Login if it doesn't already exist
IF NOT EXISTS
  (SELECT name 
    FROM master.sys.server_principals 
    WHERE name = '${MSSQL_USER}')
  BEGIN
    CREATE LOGIN [${MSSQL_USER}] WITH PASSWORD=N'${MSSQL_PASSWORD}', DEFAULT_DATABASE=[${MSSQL_DATABASE}], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
  END
GO
-- Create Database User if it doesn't already exist
IF NOT EXISTS
  (SELECT name
    FROM sys.database_principals
    WHERE name= '${MSSQL_USER}')
  BEGIN
    CREATE USER [${MSSQL_USER}] FOR LOGIN [${MSSQL_USER}] WITH DEFAULT_SCHEMA=[dbo]
  END
ELSE
  BEGIN
    ALTER USER [${MSSQL_USER}] WITH LOGIN = [${MSSQL_USER}]
  END
GO
IF IS_ROLEMEMBER ('db_owner', '${MSSQL_USER}') = 0
BEGIN
  ALTER ROLE [db_owner] ADD MEMBER [${MSSQL_USER}]
END
GO