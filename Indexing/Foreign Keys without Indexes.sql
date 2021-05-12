/*******************************************************************************************************************
*** Foreign Keys with no index
*** 
*** List foreign keys without indexes across server
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

	WITH FKTable AS (
		SELECT SCHEMA_NAME(o.schema_id) AS ''parent_schema_name'',
		OBJECT_NAME(FKC.parent_object_id) ''parent_table_name'',
		OBJECT_NAME(constraint_object_id) AS ''constraint_name'',
		SCHEMA_NAME(RO.Schema_id) AS ''referenced_schema'',
		OBJECT_NAME(referenced_object_id) AS ''referenced_table_name'',
		(SELECT ''['' + COL_NAME(k.parent_object_id, parent_column_id) + '']''  AS [data()]
		 FROM sys.foreign_key_columns (NOLOCK) AS k
		 INNER JOIN sys.foreign_keys (NOLOCK)
			ON k.constraint_object_id = object_id
			AND k.constraint_object_id = FKC.constraint_object_id
		 ORDER BY constraint_column_id
		 FOR XML PATH('''')
		) AS ''parent_colums'',
		(SELECT ''['' + COL_NAME(k.referenced_object_id, referenced_column_id) + '']'' AS [data()]
		 FROM  sys.foreign_key_columns (NOLOCK) AS k
		 INNER JOIN sys.foreign_keys (NOLOCK)
			ON k.constraint_object_id = object_id
			AND k.constraint_object_id = FKC.constraint_object_id
		 ORDER BY constraint_column_id
		 FOR XML PATH('''')
		) AS ''referenced_columns''
		FROM sys.foreign_key_columns FKC (NOLOCK)
		INNER JOIN sys.objects o (NOLOCK) 
			ON FKC.parent_object_id = o.object_id
		INNER JOIN sys.objects RO (NOLOCK)
			ON FKC.referenced_object_id = RO.object_id
		WHERE o.type = ''U''
			AND RO.type =''U''
		GROUP BY o.schema_id, RO.schema_id, FKC.parent_object_id, constraint_object_id, referenced_object_id
	),
	/* Index Columns */
	IndexColumnsTable AS(
		SELECT SCHEMA_NAME(o.schema_id) AS ''schema_name'',
		OBJECT_NAME(o.object_id) AS ''TableName'',
		(SELECT CASE key_ordinal
			WHEN 0 THEN NULL
			ELSE ''['' + COL_NAME(k.object_id, column_id) + '']''
			END AS [data()]
		 FROM sys.index_columns (NOLOCK) AS k
		 WHERE k.object_id = i.object_id
			AND k.index_id = i.index_id
		 ORDER BY key_ordinal, column_id
		 FOR XML PATH('''')
		 ) AS ''cols''
		FROM sys.indexes (NOLOCK) AS i
		INNER JOIN sys.objects o (NOLOCK)
			ON i.object_id = o.object_id
		INNER JOIN sys.index_columns ic (NOLOCK)
			ON ic.object_id = i.object_id
			AND ic.index_id =i.index_id
		INNER JOIN sys.columns c (NOLOCK)
			ON c.object_id = ic.object_id 
			AND c.column_id = ic.column_id
		WHERE o.type =''U'' 
			AND i.index_id > 0
		GROUP BY o.schema_id, o.object_id, i.object_id, i.Name, i.index_id, i.type
	),
	FKWithoutIndexTable AS (
		SELECT
		fk.parent_schema_name AS ''SchemaName'',
		fk.parent_table_name AS ''TableName'',
		fk.referenced_schema AS ''ReferencedSchemaName'',
		fk.referenced_table_name AS ''ReferencedTableName'',
		fk.constraint_name AS ''ConstraintName''
		FROM FKTable fk
		WHERE NOT EXISTS (SELECT 1
						  FROM IndexColumnsTable ict
						  WHERE fk.parent_schema_name = ict.schema_name
							AND fk.parent_table_name = ict.TableName
							AND fk.parent_colums = LEFT(ict.cols, LEN(fk.parent_colums))
						  )
	)
	SELECT DB_NAME() AS DatabaseName,
		SchemaName,
		TableName,
		ReferencedSchemaName,
		ReferencedTableName,
		ConstraintName
	FROM  FKWithoutIndexTable
	ORDER BY DatabaseName,SchemaName,TableName'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
