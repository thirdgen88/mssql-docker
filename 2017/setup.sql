CREATE DATABASE [${MSSQL_DATABASE}]
GO
USE [${MSSQL_DATABASE}]
GO
CREATE LOGIN [${MSSQL_USER}] WITH PASSWORD=N'${MSSQL_PASSWORD}', DEFAULT_DATABASE=[${MSSQL_DATABASE}], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE USER [${MSSQL_USER}] FOR LOGIN [${MSSQL_USER}] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [${MSSQL_USER}]