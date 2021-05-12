/*******************************************************************************************************************
*** Index Usage and Space Used
*** 
*** Lists indexes/tables, their statistics and space usage
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/


SELECT t.[name] AS 'TableName',
i.name AS 'IndexName',
CASE
	WHEN i.[type] IN (0,1) THEN 'Table'
	WHEN i.[type] = 2 THEN 'Index'
END AS 'Type',
ds.[name] AS 'Filegroup',
p.rows,
(au.total_pages * 8 / 1024) AS 'Size(MB)',
ius.user_seeks,
ius.user_scans,
ius.user_lookups,
ius.user_updates,
ius.last_user_seek,
ius.last_user_scan,
ius.last_user_lookup,
ius.last_user_update,
ius.system_seeks,
ius.system_scans,
ius.system_lookups,
ius.system_updates,
ius.last_system_seek,
ius.last_system_scan,
ius.last_system_lookup,
ius.last_system_update
FROM sys.tables t
INNER JOIN sys.indexes i
	ON t.object_id = i.object_id
INNER JOIN sys.partitions p
	ON i.object_id = p.object_id
	AND i.index_id = p.index_id
INNER JOIN sys.allocation_units au
	ON p.hobt_id = au.container_id
INNER JOIN sys.data_spaces ds
	ON au.data_space_id = ds.data_space_id
INNER JOIN sys.dm_db_index_usage_stats ius
	ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE i.[type] = 1 --ncx
AND (au.total_pages * 8 / 1024) > 1000
ORDER BY (au.total_pages * 8 / 1024) DESC
