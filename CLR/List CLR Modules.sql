/*******************************************************************************************************************
*** List CLR Modules
*** 
*** List any CLR modules on the server
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/


USE master
GO

DECLARE dbnames CURSOR 
FOR
SELECT name
FROM sys.databases
WHERE database_id > 4
AND state_desc = 'ONLINE'
ORDER BY name ASC

DECLARE @dbname VARCHAR(256);
DECLARE @SQL VARCHAR(MAX);

OPEN dbnames

FETCH NEXT FROM dbnames INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN

	SET @SQL = 'USE [' + @dbname +'];

	SELECT DB_NAME(DB_ID()) AS ''Database'', *
	FROM sys.assembly_modules

	SELECT DB_NAME(DB_ID()) AS ''Database'', *
	FROM sys.assembly_types
	WHERE name NOT IN (''hierarchyid'', ''geometry'', ''geography'')

	SELECT DB_NAME(DB_ID()) AS ''Database'', *
	FROM sys.assemblies
	WHERE name <> ''Microsoft.SqlServer.Types'';'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
