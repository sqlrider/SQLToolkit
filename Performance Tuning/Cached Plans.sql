/*******************************************************************************************************************
*** Cached Plans
***
*** A few queries for looking at plan caching in a given database (or query text, etc) including multiple plans for
*** the same query text.
***
*** Ver		Date		Author
*** 1.0		17/09/18	Alex Stuart
***
********************************************************************************************************************/

USE master
GO

SELECT ecp.bucketid, ecp.usecounts, ecp.size_in_bytes / 1024 AS 'SizeKB', ecp.cacheobjtype, est.text
FROM sys.dm_exec_cached_plans ecp
CROSS APPLY sys.dm_exec_sql_text(ecp.plan_handle) est
WHERE est.dbid = 5
ORDER BY usecounts DESC

SELECT est.text, COUNT(*) AS 'Plans'
FROM sys.dm_exec_cached_plans ecp
CROSS APPLY sys.dm_exec_sql_text(ecp.plan_handle) est
WHERE est.dbid = 5
GROUP BY est.[text]
ORDER BY COUNT(*) DESC
