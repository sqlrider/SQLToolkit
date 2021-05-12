/*****************************************************************************************************
*** Create Logins and Users
***
*** Utility script with common statements for creating logins/users and role memberships.
***
*** Ver		Date		Author				Change
*** 1.0		01/10/18	Alex Stuart			Initial version.
***
******************************************************************************************************/


USE master
GO

----------------------- Logins -------------------------

SELECT *
FROM sys.server_principals
WHERE [type] = 'S'

--- Create SQL login
CREATE LOGIN [loginname]
WITH PASSWORD = 'password',
CHECK_EXPIRATION = OFF,
CHECK_POLICY = OFF,
DEFAULT_DATABASE = [database]


--- Create Windows login
CREATE LOGIN [domain\username]
FROM WINDOWS

-- Deny connect
DENY CONNECT TO [domain\username]

--- Drop login
DROP LOGIN [domain\username]

-- View login groups
SELECT *
FROM sys.server_principals
WHERE [type] = 'G'
ORDER BY name ASC


------------ Database users ---------------
USE [databasename]
GO

-- Add user
CREATE USER [domain\username]
FROM LOGIN [domain\username]

-- Drop user
DROP USER [domain\username]

-- View roles
SELECT *
FROM sys.database_principals
WHERE [type] = 'R'

-- View groups
SELECT *
FROM sys.database_principals
WHERE [type] = 'G'

-- View users
SELECT *
FROM sys.database_principals
WHERE [type] = 'U'


-------------- 2012+ ---------------
-- Add users
ALTER ROLE db_datareader
ADD MEMBER [domain\username]

ALTER ROLE db_datawriter
ADD MEMBER [domain\username]

ALTER ROLE db_owner
ADD MEMBER [domain\username]

-- Remove users
ALTER ROLE db_datareader
DROP MEMBER [domain\username]

ALTER ROLE db_datawriter
DROP MEMBER [domain\username]

--------------- 2008R2 and below ---------------
-- Add user
EXEC sp_addrolemember @rolename = 'db_datareader', @membername = 'domain\username'
EXEC sp_addrolemember @rolename = 'db_datawriter', @membername = 'domain\username'

-- Remove user
EXEC sp_droprolemember @rolename = 'db_datareader', @membername = 'domain\username'


---- Read-only DB add user ---------
USE [databasename]
GO

ALTER DATABASE databasename
SET READ_WRITE

CREATE USER [domain\user]
FROM LOGIN [domain\user]

EXEC sp_addrolemember @rolename = 'db_datareader', @membername = 'domain\username'

ALTER DATABASE databasename
SET READ_ONLY




