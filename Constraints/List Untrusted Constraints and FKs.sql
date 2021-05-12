/**************************************************************************************
*** Untrusted Constraints and FKs
*** 
*** List untrusted constraints and foreign keys
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
***************************************************************************************/


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

SELECT DB_NAME(DB_ID()) AS ''Database'', 
	QUOTENAME(SCHEMA_NAME(i.schema_id)) + ''.'' + QUOTENAME(o.name) AS TableName,
	i.name AS ConstraintName,
	''ALTER TABLE '' + QUOTENAME(SCHEMA_NAME(i.schema_id)) + ''.'' + QUOTENAME(o.name) + '' WITH CHECK CHECK CONSTRAINT ['' + i.name + '']'' AS CheckCommand
FROM sys.check_constraints AS i
INNER JOIN sys.objects AS o
	ON i.parent_object_id = o.OBJECT_ID
WHERE i.is_not_trusted = 1
	AND i.is_not_for_replication = 0
UNION ALL
SELECT DB_NAME(DB_ID()) AS ''Database'',
	QUOTENAME(SCHEMA_NAME(i.schema_id)) + ''.'' + QUOTENAME(o.name) AS TableName,
	i.name AS ConstraintName,
	''ALTER TABLE '' + QUOTENAME(SCHEMA_NAME(i.schema_id)) + ''.'' + QUOTENAME(o.name) + '' WITH CHECK CHECK CONSTRAINT ['' + i.name + '']'' AS CheckCommand
FROM sys.foreign_keys AS i
INNER JOIN sys.objects AS o
	ON i.parent_object_id = o.OBJECT_ID
WHERE i.is_not_trusted = 1
	AND i.is_not_for_replication = 0
ORDER BY TableName, ConstraintName;'


	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
