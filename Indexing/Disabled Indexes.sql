/*******************************************************************************************************************
*** Disabled Indexes
*** 
*** Lists disabled indexes across server
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

	SELECT DISTINCT SCHEMA_NAME(a.[schema_id]) AS ''SchemaName'',
	OBJECT_NAME(a.[object_id]) AS ''TableName'',
	a.[object_id] AS ''object_id'',
	b.name AS ''IndexName'',
	b.index_id AS ''index_id'',
	b.[type] AS ''Type'',
	b.type_desc AS ''IndexType'',
	b.is_disabled AS ''Disabled''
	FROM sys.objects a (NOLOCK)
	INNER JOIN sys.indexes b (NOLOCK)
		ON b.object_id = a.object_id 
	WHERE a.is_ms_shipped = 0
		AND a.object_id NOT IN (SELECT major_id
								FROM sys.extended_properties (NOLOCK)
								WHERE name = N''microsoft_database_tools_support'')
		AND b.is_disabled = 1
	ORDER BY 1,2'


	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
