/*******************************************************************************************************************
*** Users with DBO
*** 
*** Lists users with DBO access across all DBs on instance. From Microsoft RAP
***
*** Ver		Date		Author
*** 1.0		14/09/18	Alex Stuart
*** 
********************************************************************************************************************/

USE master
GO

SET NOCOUNT ON

DECLARE @dbname SYSNAME

CREATE TABLE #SQLRAP_DBSecurityCheck
(
    DatabaseName SYSNAME,
    UserName  SYSNAME,
    RoleName  NVARCHAR(10)
)

DECLARE GetTheDatabases CURSOR FOR
SELECT name
FROM master.sys.databases
WHERE state_desc = N'ONLINE'
AND is_distributor = 0
ORDER BY database_id
OPTION (MAXDOP 1)

OPEN GetTheDatabases

FETCH NEXT FROM GetTheDatabases INTO @dbname

WHILE @@FETCH_STATUS = 0

BEGIN
    EXEC('USE [' + @dbname + '];

            INSERT #SQLRAP_DBSecurityCheck (DatabaseName, UserName, RoleName)
            SELECT db_name(),
                member.name,
                [role].name
			FROM sys.database_principals member
			INNER JOIN sys.database_role_members rm
				ON member.principal_id = rm.member_principal_id
			INNER JOIN sys.database_principals [role]
				ON [role].principal_id = rm.role_principal_id
			WHERE [role].name in (''dbo'',''db_owner'')
				AND member.name not in (''db'',''db_owner'')
				AND member.name not in (''dbo'')
				ORDER BY member.name, [role].name
                OPTION (MAXDOP 1)')

    FETCH NEXT FROM GetTheDatabases INTO @dbname       

END

CLOSE GetTheDatabases
DEALLOCATE GetTheDatabases

SELECT  DatabaseName AS 'Database Name',
        UserName AS 'User With Elevated Privilege',
        RoleName AS 'Privilege Held By Credential'
FROM #SQLRAP_DBSecurityCheck
ORDER BY DatabaseName, UserName
OPTION (MAXDOP 1)

DROP TABLE #SQLRAP_DBSecurityCheck
