/**************************************************************************************
*** Test Access
*** 
*** Check and test a user's access to an instance/database 
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
***************************************************************************************/

USE master
GO

-- Display login/permission path
EXEC xp_logininfo [domain\user], 'all'

-- Impersonate login for rest of script
EXECUTE AS LOGIN = 'domain\user'
GO

-- Identify login's reported login and user names
SELECT SUSER_SNAME() AS 'Login', USER_NAME() AS 'User';

-- Display server permissions
SELECT *
FROM sys.fn_my_permissions(NULL, 'SERVER')

 
---- Database Access

USE [databasename]
GO

-- Identify login's login and user names
SELECT SUSER_SNAME() AS 'Login', USER_NAME() AS 'User'

-- Display effective database permissions
SELECT *
FROM sys.fn_my_permissions(NULL, 'DATABASE')

-- Test query
SELECT *
FROM dbo.tablename


-- Revert impersonation
USE MASTER
GO
REVERT
