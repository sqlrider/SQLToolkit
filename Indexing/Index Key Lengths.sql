/*******************************************************************************************************************
*** Index Key Lengths
*** 
*** Find key length of indexes across DB
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

	SELECT [Database], [Schema], [Table], [Index], [Type], SUM(max_length) AS ''MaxLength''
	FROM (
		SELECT DB_NAME(DB_ID()) AS ''Database'', s.name AS ''Schema'', o.name AS ''Table'', i.name AS ''Index'', i.type_desc AS ''Type'', ic.index_column_id, c.max_length
		FROM sys.indexes i
		INNER JOIN sys.objects o
			ON i.object_id = o.object_id
		INNER JOIN sys.schemas s
			ON o.schema_id = s.schema_id
		INNER JOIN sys.index_columns ic
			ON i.object_id = ic.object_id AND i.index_id = ic.index_id
		INNER JOIN sys.columns c
			ON i.object_id = c.object_id AND ic.column_id = c.column_id
		WHERE o.[type] IN (''U'', ''V'')
			AND i.type_desc IN (''CLUSTERED'', ''NONCLUSTERED'')
	) a
	GROUP BY [Database], [Schema], [Table], [Index], [Type]
	HAVING SUM(max_length) > 900
	ORDER BY [Table] ASC
	;'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
