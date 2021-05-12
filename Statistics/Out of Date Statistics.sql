
/*******************************************************************************************************************
*** Out of Date Statistics
*** 
*** List out-of-date statistics
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
********************************************************************************************************************/

USE master
GO

DECLARE @Major INT,
@Minor INT,
@build INT,
@revision INT,
@i INT,
@str NVARCHAR(100),
@str2 NVARCHAR(10)

 

SET @str=cast(serverproperty('ProductVersion') as NVARCHAR(100))
SET @str2=left(@str,charindex('.',@str))
SET @i=len(@str)
SET @str=right(@str,@i-charindex('.',@str))
SET @Major=CAST(Replace(@STR2,'.','') AS INT)
SET @str2=left(@str,charindex('.',@str))
SET @i=len(@str)
SET @str=right(@str,@i-charindex('.',@str))
SET @Minor=CAST(Replace(@STR2,'.','') AS INT)
SET @str2=left(@str,charindex('.',@str))
SET @i=len(@str)
SET @str=right(@str,@i-charindex('.',@str))
SET @Build=CAST(Replace(@STR2,'.','') AS INT)
SET @revision=CAST(@str as int)

IF @Major < 10
	SET @i = 1
ELSE
	IF @Major > 10
		SET @i = 0
	ELSE
		IF @minor = 50 AND @Build >= 4000
			SET @i = 0
		ELSE
			SET @i = 1


IF @i = 1
	BEGIN
	EXEC sp_executesql N';
	
		WITH StatTables AS (
			SELECT so.schema_id AS ''schema_id'',     
					so.name  AS ''TableName'',
					so.object_id AS ''object_id'',
					CASE INDEXPROPERTY(so.object_id, dmv.name, ''IsStatistics'')
						WHEN 0 THEN dmv.rows
						ELSE (SELECT TOP 1 row_count
							  FROM sys.dm_db_partition_stats ps (NOLOCK)
							  WHERE ps.object_id = so.object_id 
								AND ps.index_id in (1,0))
						END AS ''ApproximateRows'',
					dmv.rowmodctr AS ''RowModCtr''
					FROM sys.objects so (NOLOCK)
					INNER JOIN sysindexes dmv (NOLOCK)
						ON so.object_id = dmv.id
					LEFT JOIN sys.indexes si (NOLOCK)
						ON so.object_id = si.object_id 
						AND so.type in (''U'',''V'')
						AND si.index_id  = dmv.indid
					WHERE so.is_ms_shipped = 0
						AND dmv.indid<>0
						AND so.object_id NOT IN (SELECT major_id 
												 FROM sys.extended_properties (NOLOCK)
												 WHERE name = N''microsoft_database_tools_support'')
		),
		StatTableGrouped AS (
			SELECT ROW_NUMBER() OVER(ORDER BY TableName) AS seq1,
				ROW_NUMBER() OVER(ORDER BY TableName DESC) AS seq2,
				TableName,
				CAST(MAX(ApproximateRows) AS BIGINT) AS ApproximateRows,
				CAST(MAX(RowModCtr) AS BIGINT) AS RowModCtr,
				schema_id,
				object_id
				FROM StatTables st
				GROUP BY schema_id, object_id, TableName
				HAVING (MAX(ApproximateRows) > 500 AND MAX(RowModCtr) > (MAX(ApproximateRows)*0.2 + 500 ))
		)
		SELECT @@SERVERNAME AS InstanceName,
			seq1 + seq2 - 1 AS NbOccurences,
			SCHEMA_NAME(stg.schema_id) AS ''SchemaName'', 
			stg.TableName,
			CASE OBJECTPROPERTY(stg.object_id, ''TableHasClustIndex'')
				WHEN 1 THEN ''Clustered''
				WHEN 0 THEN ''Heap''
				ELSE ''Indexed View''
			END AS ClusteredHeap,
			CASE objectproperty(stg.object_id, ''TableHasClustIndex'')
				WHEN 0 THEN (SELECT COUNT(*)
							 FROM sys.indexes i (NOLOCK)
							 WHERE i.object_id= stg.object_id) - 1
				ELSE (SELECT COUNT(*)
					  FROM sys.indexes i (NOLOCK)
					  WHERE i.object_id = stg.object_id)
			END AS IndexCount,
			(SELECT COUNT(*)
			 FROM sys.columns c (NOLOCK)
			 WHERE c.object_id = stg.object_id) AS ColumnCount,
			(SELECT COUNT(*)
			 FROM sys.stats s (NOLOCK)
			 WHERE s.object_id = stg.object_id) AS StatCount,
			 stg.ApproximateRows,
			 stg.RowModCtr,
			 stg.schema_id,
			 stg.object_id
			 FROM StatTableGrouped stg'

	END
ELSE
	BEGIN
		EXEC sp_executesql N';
		
		WITH StatTables AS (
			SELECT so.schema_id AS ''schema_id'',     
			so.name  AS ''TableName'',
			so.object_id AS ''object_id'',
			ISNULL(sp.rows,0) AS ''ApproximateRows'',
			ISNULL(sp.modification_counter,0) AS ''RowModCtr''
			FROM sys.objects so (NOLOCK)
			INNER JOIN sys.stats st (NOLOCK)
				ON so.object_id = st.object_id
			CROSS APPLY sys.dm_db_stats_properties(so.object_id, st.stats_id) AS sp
			WHERE so.is_ms_shipped = 0
			AND st.stats_id<>0
			AND so.object_id NOT IN (SELECT major_id
									 FROM sys.extended_properties (NOLOCK)
									 WHERE name = N''microsoft_database_tools_support'')
		),
		StatTableGrouped AS (
			SELECT 
			ROW_NUMBER() OVER(ORDER BY TableName) AS seq1,
			ROW_NUMBER() OVER(ORDER BY TableName DESC) AS seq2,
			TableName,
			CAST(MAX(ApproximateRows) AS bigint) AS ApproximateRows,
			CAST(MAX(RowModCtr) AS bigint) AS RowModCtr,
			COUNT(*) AS StatCount,
			schema_id,
			object_id
			FROM StatTables st
			GROUP BY schema_id,object_id,TableName
			HAVING (MAX(ApproximateRows) > 500 AND MAX(RowModCtr) > (MAX(ApproximateRows)*0.2 + 500 ))
		)
		SELECT @@SERVERNAME AS InstanceName,
			seq1 + seq2 - 1 AS NbOccurences,
			SCHEMA_NAME(stg.schema_id) AS ''SchemaName'', 
			stg.TableName,
			CASE OBJECTPROPERTY(stg.object_id, ''TableHasClustIndex'')
				WHEN 1 THEN ''Clustered''
				WHEN 0 THEN ''Heap''
				ELSE ''Indexed View''
			END AS ClusteredHeap,
			CASE OBJECTPROPERTY(stg.object_id, ''TableHasClustIndex'')
				WHEN 0 THEN (SELECT COUNT(*)
							 FROM sys.indexes i (NOLOCK)
							 WHERE i.object_id = stg.object_id) - 1
				ELSE (SELECT COUNT(*) 
					  FROM sys.indexes i (NOLOCK)
					  WHERE i.object_id = stg.object_id)
			END AS IndexCount,
			(SELECT COUNT(*)
			 FROM sys.columns c (NOLOCK)
			 WHERE c.object_id = stg.object_id ) AS ColumnCount,
			stg.StatCount,
			stg.ApproximateRows,
			stg.RowModCtr,
			stg.schema_id,
			stg.object_id
			FROM StatTableGrouped stg'
	END 


-- For every database

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

		SET @SQL = N'; 
		
		USE [' + @dbname + '];
		
		WITH StatTables AS (
			SELECT so.schema_id AS ''schema_id'',     
			so.name  AS ''TableName'',
			so.object_id AS ''object_id'',
			ISNULL(sp.rows,0) AS ''ApproximateRows'',
			ISNULL(sp.modification_counter,0) AS ''RowModCtr''
			FROM sys.objects so (NOLOCK)
			INNER JOIN sys.stats st (NOLOCK)
				ON so.object_id = st.object_id
			CROSS APPLY sys.dm_db_stats_properties(so.object_id, st.stats_id) AS sp
			WHERE so.is_ms_shipped = 0
			AND st.stats_id<>0
			AND so.object_id NOT IN (SELECT major_id
									 FROM sys.extended_properties (NOLOCK)
									 WHERE name = N''microsoft_database_tools_support'')
		),
		StatTableGrouped AS (
			SELECT 
			ROW_NUMBER() OVER(ORDER BY TableName) AS seq1,
			ROW_NUMBER() OVER(ORDER BY TableName DESC) AS seq2,
			TableName,
			CAST(MAX(ApproximateRows) AS bigint) AS ApproximateRows,
			CAST(MAX(RowModCtr) AS bigint) AS RowModCtr,
			COUNT(*) AS StatCount,
			schema_id,
			object_id
			FROM StatTables st
			GROUP BY schema_id,object_id,TableName
			HAVING (MAX(ApproximateRows) > 500 AND MAX(RowModCtr) > (MAX(ApproximateRows)*0.2 + 500 ))
		)
		SELECT DB_NAME(DB_ID()) AS ''Database'',
			seq1 + seq2 - 1 AS NbOccurences,
			SCHEMA_NAME(stg.schema_id) AS ''SchemaName'', 
			stg.TableName,
			CASE OBJECTPROPERTY(stg.object_id, ''TableHasClustIndex'')
				WHEN 1 THEN ''Clustered''
				WHEN 0 THEN ''Heap''
				ELSE ''Indexed View''
			END AS ClusteredHeap,
			CASE OBJECTPROPERTY(stg.object_id, ''TableHasClustIndex'')
				WHEN 0 THEN (SELECT COUNT(*)
							 FROM sys.indexes i (NOLOCK)
							 WHERE i.object_id = stg.object_id) - 1
				ELSE (SELECT COUNT(*) 
					  FROM sys.indexes i (NOLOCK)
					  WHERE i.object_id = stg.object_id)
			END AS IndexCount,
			(SELECT COUNT(*)
			 FROM sys.columns c (NOLOCK)
			 WHERE c.object_id = stg.object_id ) AS ColumnCount,
			stg.StatCount,
			stg.ApproximateRows,
			stg.RowModCtr,
			stg.schema_id,
			stg.object_id
			FROM StatTableGrouped stg'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
