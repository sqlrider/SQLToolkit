/*****************************************************************************************************
*** For Every Database
***
*** Template for executing a SQL query on every (user) database on an instance.
***
*** Ver		Date		Author				Change
*** 1.0		01/10/18	Alex Stuart			Initial version.
***
******************************************************************************************************/

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

	;'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;



