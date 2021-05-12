/*******************************************************************************************************************
*** Heaps
*** 
*** Lists tables without clustered indexes across DBs on server
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

	SELECT DISTINCT DB_NAME(DB_ID()) AS ''Database'',
		SCHEMA_NAME(so.[schema_id]) AS ''SchemaName'',
		OBJECT_NAME(so.[object_id]) AS ''TableName'',
		so.[object_id] AS ''object_id'',
		MAX(dmv.[rows]) AS ''ApproximateRows'',
		CASE OBJECTPROPERTY(MAX(so.[object_id]), ''TableHasClustIndex'')
			WHEN 0 THEN COUNT(si.index_id) - 1
			ELSE COUNT(si.index_id)
		END AS ''IndexCount'',
		MAX(d.ColumnCount) AS ''ColumnCount''
	FROM sys.objects so (NOLOCK)
	INNER JOIN sys.indexes si (NOLOCK)
		ON so.[object_id] = si.[object_id] 
		AND so.type IN (N''U'',N''V'')
	INNER JOIN sysindexes dmv (NOLOCK)
		ON so.[object_id] = dmv.id 
		AND si.index_id = dmv.indid
	FULL OUTER JOIN (SELECT [object_id], COUNT(1) AS ''ColumnCount''
					 FROM sys.columns (NOLOCK)
					 GROUP BY [object_id]) d
		ON d.[object_id] = so.[object_id]
	WHERE so.is_ms_shipped = 0
		AND so.[object_id] NOT IN (SELECT major_id
								   FROM sys.extended_properties (NOLOCK)
								   WHERE name = N''microsoft_database_tools_support'')
		AND INDEXPROPERTY(so.[object_id], si.name, ''IsStatistics'') = 0
	GROUP BY so.[schema_id], so.[object_id]
	HAVING OBJECTPROPERTY(MAX(so.[object_id]), ''TableHasClustIndex'') = 0
		AND COUNT(si.index_id)-1 > 0
	ORDER BY SchemaName, TableName'


	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
