/*******************************************************************************************************************
*** Index Stats
*** 
*** Check index operational/usage stats
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/

USE master
GO

DECLARE @dbname SYSNAME;
DECLARE @tablename SYSNAME;

SET @dbname = 'databasename';
SET @tablename = 'schemaname.tablename';

SELECT *
FROM sys.dm_db_index_operational_stats(DB_ID(@dbname), OBJECT_ID(@tablename), NULL, NULL)

SELECT *
FROM sys.dm_db_index_physical_stats (DB_ID(@dbname), OBJECT_ID(@tablename), NULL, NULL, 'DETAILED')  

SELECT *
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID(@dbname)
AND object_id = OBJECT_ID(@tablename)
