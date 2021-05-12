/*******************************************************************************************************************
*** Missing Indexes
*** 
*** Lists any missing indexes per database with 'IndexAdvantage' benefit calculation
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


SELECT DB_NAME(DB_ID()) AS ''Database'',
                id.[object_id] AS [ObjectID],
                id.[statement] AS [ObjectName],
                id.[equality_columns] AS [EqualityColumns],
                id.[inequality_columns] AS [InEqualityColumns],
                id.[included_columns] AS [IncludedColumns],
				gs.user_seeks,
				gs.user_scans,
                CONVERT (decimal (28,1), gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)) AS [IndexAdvantage],
        gs.[last_user_seek] AS [LastUserSeekTime],
                gs.[last_user_scan] AS [LastUserScanTime],
                gs.[avg_total_user_cost] AS [AvgTotalUserCost],
                gs.[avg_user_impact] AS [AvgUserImpact],
                gs.[avg_system_impact] AS [AvgSystemImpact]
FROM    [sys].[dm_db_missing_index_group_stats] AS gs WITH (NOLOCK)
        INNER JOIN [sys].[dm_db_missing_index_groups] AS ig WITH (NOLOCK) ON gs.[group_handle] = ig.[index_group_handle]
        INNER JOIN [sys].[dm_db_missing_index_details] AS id WITH (NOLOCK) ON ig.[index_handle] = id.[index_handle]
        INNER JOIN [sys].[databases] AS db WITH (NOLOCK) ON db.[database_id] = id.[database_id]
WHERE  id.[database_id] = DB_ID() AND CONVERT (decimal (28,1), gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)) > 10 AND (gs.user_seeks + gs.user_scans) > 1000
ORDER BY gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans) DESC'


	EXEC(@SQL);

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames;
