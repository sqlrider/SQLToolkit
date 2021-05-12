/*********************************************************************************************
*** Fill Factor 
*** 
*** List fill factor and space savings from 100% for all indexes on all DBs on server
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
**********************************************************************************************/

USE master
GO

SET NOCOUNT ON

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

	WITH cte_fill AS
	( 
		SELECT i.index_id,
			i.fill_factor,
			ps.used_page_count,
			(ps.used_page_count * 8) / 1024 AS ''Size(MB)'',
			((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00) AS ''NewSize(MB)'', 
			CAST(((ps.used_page_count * 8) / 1024) - (((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00)) AS DECIMAL(10,2)) AS ''Saving(MB)''
		FROM sys.indexes i
		INNER JOIN sys.dm_db_partition_stats ps
			ON i.[object_id] = ps.[object_id]
			AND i.index_id = ps.index_id
		WHERE i.fill_factor > 0
		AND ps.used_page_count > 0
	)
	SELECT DB_NAME(DB_ID()) AS ''Database'', ''-'' AS ''-'', SUM([Saving(MB)]) AS ''Saving(MB)''
	FROM cte_fill

	;'

	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;


--  Calculate cost savings of using fillfactor 100
SELECT i.index_id,
	i.fill_factor,
	ps.used_page_count,
	(ps.used_page_count * 8) / 1024 AS 'Size(MB)',
	((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00) AS 'NewSize(MB)', 
	CAST(((ps.used_page_count * 8) / 1024) - (((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00)) AS DECIMAL(10,2)) AS 'Saving(MB)'
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps
	ON i.[object_id] = ps.[object_id]
	AND i.index_id = ps.index_id
WHERE i.fill_factor > 0
AND ps.used_page_count > 0

-- Calculate cost saving of using fillfactor 100 per DB
WITH cte_fill AS
( 
	SELECT i.index_id,
		i.fill_factor,
		ps.used_page_count,
		(ps.used_page_count * 8) / 1024 AS 'Size(MB)',
		((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00) AS 'NewSize(MB)', 
		CAST(((ps.used_page_count * 8) / 1024) - (((ps.used_page_count * 8) / 1024) * (i.fill_factor / 100.00)) AS DECIMAL(10,2)) AS 'Saving(MB)'
	FROM sys.indexes i
	INNER JOIN sys.dm_db_partition_stats ps
		ON i.[object_id] = ps.[object_id]
		AND i.index_id = ps.index_id
	WHERE i.fill_factor > 0
	AND ps.used_page_count > 0
)
SELECT DB_NAME(DB_ID()) AS 'Database', SUM([Saving(MB)]) AS 'Saving(MB)'
FROM cte_fill


-- List index count grouped by fillfactor
CREATE TABLE #fillfactor
([Database] SYSNAME,
ObjectID INT,
[FillFactor] INT)

INSERT INTO #fillfactor
SELECT DB_NAME(DB_ID()), object_id, fill_factor
FROM sys.indexes WITH (NOLOCK)
WHERE [type] <> 0
AND object_id > 100

SELECT COUNT(*) AS 'Indexes', [FillFactor]
FROM #fillfactor
GROUP BY [FillFactor]
ORDER BY [FillFactor] ASC



