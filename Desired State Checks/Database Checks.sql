/**************************************************************************************
*** Database Checks
*** 
*** A collection of various best-practise checks to run on a server/database.
***
*** Ver		Date		Author
*** 1.0		08/03/17	Alex Stuart
*** 
***************************************************************************************/

USE master
GO

--  No backups < 7 days
SELECT Name
FROM master.sys.databases
WHERE name NOT IN (
	SELECT database_name as lastbackup
	FROM msdb..backupset
	WHERE type = 'D'
	GROUP BY database_name, type
	HAVING MAX(backup_start_date) >= DATEADD(D,-7,GETDATE()))


-- DBs in SIMPLE recovery mode
SELECT Name, recovery_model_desc
FROM sys.databases
WHERE recovery_model_desc = 'SIMPLE'


-- DBs with % autogrowth
SELECT mf.database_id,
		DB_NAME(mf.database_id) AS database_name,
		mf.name AS [Filename],
		mf.growth AS Percentage_growth,
		 CAST((mf.size*8) AS FLOAT) /1024 as 'DBSize(MB)', 
		 CAST((mf.size*8*growth) AS FLOAT)/100/1024 as 'NextGrowth(MB)',
		 mf.type_desc AS Filetype
FROM sys.master_files mf
INNER JOIN sys.databases d
	ON mf.database_id = d.database_id
WHERE mf.is_percent_growth=1
AND mf.is_read_only = 0
AND d.is_read_only = 0
AND d.database_id <> 1
ORDER BY DB_NAME(mf.database_id) ASC


-- DBs with auto-shrink enabled
SELECT name
FROM sys.databases
WHERE is_auto_shrink_on = 1

-- Log files > 1GB
SELECT
database_id,
DB_NAME(database_id) AS database_name,
name AS Log_Filename,
is_percent_growth As growth_in_percentage_set,
CASE
	WHEN is_percent_growth = 1 THEN growth
	ELSE 0
	END AS Percentage_growth_value,
CASE
	WHEN is_percent_growth = 1 THEN CAST((size*8) AS FLOAT) /1024
    ELSE 0
	END as File_Size_in_MB, 
CASE WHEN is_percent_growth = 1 THEN CAST((size*8*growth) AS FLOAT)/100/1024 
    ELSE CAST((8*growth) AS FLOAT)/1024
	END AS next_growth_in_MB,
    type_desc AS Filetype
FROM sys.master_files
WHERE
CASE WHEN is_percent_growth = 1 THEN CAST((size*8*growth) AS FLOAT)/100/1024 
    ELSE CAST((8*growth) AS FLOAT)/1024
	END > 1024
AND type_desc='LOG'



-- DBs with Page Verify not set to CHECKSUM
SELECT name, database_id, page_verify_option_desc
FROM sys.databases
WHERE page_verify_option < 2;


-- Suspect pages
SELECT DISTINCT
DB_NAME(database_id) as 'Database_Name',
file_id as 'File_Id',
page_id as 'Page_Id',
CASE event_type
    WHEN 1 THEN '823 or non-specific 824 error'
    WHEN 2 THEN 'Bad checksum'
    WHEN 3 THEN 'Torn page'
    WHEN 4 THEN 'Restored after marked bad'
    WHEN 5 THEN  'Repaired'
    WHEN 7 THEN  'Deallocated by DBCC'
    ELSE NULL
END as 'Event_Type',
error_count as 'Error_Count',
last_update_date as 'Last_Update_Date'
from msdb..suspect_pages

BEGIN TRAN
	DELETE 
	FROM msdb..suspect_pages
	WHERE Last_Update_Date < '2018-01-01 00:00:00.000'
COMMIT


-- Invalid logins
exec sp_validatelogins


-- NTLM Connections
SELECT *
FROM sys.dm_exec_connections
WHERE auth_scheme  = 'NTLM'
AND net_transport <> 'Shared Memory'


-- Ad-hoc query cache
SELECT S.CacheType, S.Avg_Use, S.Avg_Multi_Use,
       S.Total_Plan_3orMore_Use, S.Total_Plan_2_Use, S.Total_Plan_1_Use, S.Total_Plan,
       CAST( (S.Total_Plan_1_Use * 1.0 / S.Total_Plan) as Decimal(18,2) )[Pct_Plan_1_Use],
       S.Total_MB_1_Use,   S.Total_MB,
       CAST( (S.Total_MB_1_Use   * 1.0 / S.Total_MB  ) as Decimal(18,2) )[Pct_MB_1_Use]
  FROM
  (
    SELECT CP.objtype[CacheType],
           COUNT(*)[Total_Plan],
           SUM(CASE WHEN CP.usecounts > 2 THEN 1 ELSE 0 END)[Total_Plan_3orMore_Use],
           SUM(CASE WHEN CP.usecounts = 2 THEN 1 ELSE 0 END)[Total_Plan_2_Use],
           SUM(CASE WHEN CP.usecounts = 1 THEN 1 ELSE 0 END)[Total_Plan_1_Use],
           CAST((SUM(CP.size_in_bytes * 1.0) / 1024 / 1024) as Decimal(12,2) )[Total_MB],
           CAST((SUM(CASE WHEN CP.usecounts = 1 THEN (CP.size_in_bytes * 1.0) ELSE 0 END)
                      / 1024 / 1024) as Decimal(18,2) )[Total_MB_1_Use],
           CAST(AVG(CP.usecounts * 1.0) as Decimal(12,2))[Avg_Use],
           CAST(AVG(CASE WHEN CP.usecounts > 1 THEN (CP.usecounts * 1.0)
                         ELSE NULL END) as Decimal(12,2))[Avg_Multi_Use]
      FROM sys.dm_exec_cached_plans as CP
     GROUP BY CP.objtype
  ) AS S
 ORDER BY S.CacheType

 DECLARE @AdHocSizeInMB DECIMAL(14, 2)
        ,@TotalSizeInMB DECIMAL(14, 2)
        ,@ObjType NVARCHAR(34)

    SELECT @AdHocSizeInMB = SUM(CAST((
                    CASE 
                        WHEN usecounts = 1
                            AND LOWER(objtype) = 'adhoc'
                            THEN size_in_bytes
                        ELSE 0
                        END
                    ) AS DECIMAL(14, 2))) / 1048576
        ,@TotalSizeInMB = SUM(CAST(size_in_bytes AS DECIMAL(14, 2))) / 1048576
    FROM sys.dm_exec_cached_plans

    SELECT 'SQL Server Configuration' AS GROUP_TYPE
        ,' Total cache plan size (MB): ' + cast(@TotalSizeInMB AS VARCHAR(max)) + '. Current memory occupied by adhoc plans only used once (MB):' + cast(@AdHocSizeInMB AS VARCHAR(max)) + '.  Percentage of total cache plan occupied by adhoc plans only used once :' + cast(CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 AS DECIMAL(14, 2)) AS VARCHAR(max)) + '%' + ' ' AS COMMENTS
        ,' ' + CASE 
            WHEN @AdHocSizeInMB > 200
                OR ((@AdHocSizeInMB / @TotalSizeInMB) * 100) > 25 -- 200MB or > 25%
                THEN 'Switch on Optimize for ad hoc workloads as it will make a significant difference. Ref: http://sqlserverperformance.idera.com/memory/optimize-ad-hoc-workloads-option-sql-server-2008/. http://www.sqlskills.com/blogs/kimberly/post/procedure-cache-and-optimizing-for-adhoc-workloads.aspx'
            ELSE 'Setting Optimize for ad hoc workloads will make little difference !!'
            END + ' ' AS RECOMMENDATIONS



-- Missing Indexes
SELECT  CAST (SERVERPROPERTY('ServerName') AS NVARCHAR (256)) AS [SQLServer],
	db.[name] AS [DatabaseName],
    id.[object_id] AS [ObjectID],
    id.[statement] AS [ObjectName],
    id.[equality_columns] AS [EqualityColumns],
    id.[inequality_columns] AS [InEqualityColumns],
    id.[included_columns] AS [IncludedColumns],
    CONVERT (decimal (28,1), gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)) AS [IndexAdvantage],
    gs.[last_user_seek] AS [LastUserSeekTime],
    gs.[last_user_scan] AS [LastUserScanTime],
    gs.[avg_total_user_cost] AS [AvgTotalUserCost],
    gs.[avg_user_impact] AS [AvgUserImpact],
    gs.[avg_system_impact] AS [AvgSystemImpact]
FROM [sys].[dm_db_missing_index_group_stats] AS gs WITH (NOLOCK)
INNER JOIN [sys].[dm_db_missing_index_groups] AS ig WITH (NOLOCK)
	ON gs.[group_handle] = ig.[index_group_handle]
INNER JOIN [sys].[dm_db_missing_index_details] AS id WITH (NOLOCK)
	ON ig.[index_handle] = id.[index_handle]
INNER JOIN [sys].[databases] AS db WITH (NOLOCK)
	ON db.[database_id] = id.[database_id]
WHERE id.[database_id] = DB_ID() 
	AND CONVERT (decimal(28,1), gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)) > 10
	AND (gs.user_seeks + gs.user_scans) > 1000
ORDER BY gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans) DESC


SELECT *
FROM sys.dm_db_missing_index_details

SELECT *
FROM sys.dm_db_missing_index_groups

SELECT *
FROM sys.dm_db_missing_index_group_stats
ORDER BY (user_seeks + user_scans) DESC



-- Database files with 1MB autogrowth
SELECT DB_NAME(database_id) AS 'Database',
	   name AS 'Filename',
		is_percent_growth As 'growth_in_percentage_set',
    CASE 
		WHEN is_percent_growth = 1 THEN growth
		ELSE 0 
	END AS 'Percentage_growth_value',
    CASE 
		WHEN is_percent_growth = 1 THEN CAST((size*8) AS FLOAT) / 1024
		ELSE 0 
	END AS 'File_Size_in_MB', 
    CASE 
		WHEN is_percent_growth = 1 THEN CAST((size*8*growth) AS FLOAT) / 100/ 1024 
		ELSE CAST((8*growth) AS FLOAT) / 1024 
	END AS 'next_growth_in_MB',
    type_desc AS 'Filetype'
FROM sys.master_files
WHERE CASE
		WHEN is_percent_growth = 1 THEN CAST((size*8*growth) AS FLOAT) / 100 / 1024 
		ELSE CAST((8*growth) AS FLOAT) / 1024
	  END = 1
ORDER BY DB_NAME(database_id) ASC


-- Databases files with log files bigger than data
SELECT
d.name AS 'Database',
d.recovery_model_desc AS 'RecoveyModel',
SUM(CASE 
		WHEN [type] = 0 THEN CAST(Size AS REAL)*8/1024
		ELSE 0
	END) AS 'DATA_FILE_SIZE_IN_MB',
SUM(CASE
		WHEN [type] = 1 THEN CAST(Size AS REAL)*8/1024
		ELSE 0
	END) AS 'LOG_FILE_SIZE_IN_MB'
FROM sys.master_files mf
INNER JOIN sys.databases d 
	ON mf.database_id = d.database_id
GROUP BY mf.database_id, d.name, d.recovery_model_desc
HAVING SUM(CASE
				WHEN [type] = 0 THEN CAST(Size AS REAL)*8/1024 
				ELSE 0
			END) < SUM(CASE 
							WHEN [type] = 1 THEN CAST(Size as real)*8/1024
							ELSE 0
						END)
ORDER BY d.name ASC

-- Logins without password complexity enforced
SELECT [name] AS 'Login_name',
	[is_policy_checked]
FROM master.sys.sql_logins
WHERE [is_policy_checked] = 0
	AND name NOT LIKE '##MS_%';


-- sysadmin accounts
SELECT p.name, p.type_desc
FROM sys.server_principals r
INNER JOIN sys.server_role_members m
	ON r.principal_id = m.role_principal_id
INNER JOIN sys.server_principals p
	ON p.principal_id = m.member_principal_id
WHERE r.[type] = 'R'
	AND r.name = N'sysadmin'  


-- Old compatibility levels
SELECT name, [compatibility_level]
FROM sys.databases
WHERE [compatibility_level] < 120
ORDER BY name ASC
