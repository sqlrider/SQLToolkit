/*****************************************************************************************************
*** TrackPageSplits Extended Events
***
*** Creates an Extended Events session to monitor page splits - specifically problematic splits,
*** not end-page 'splits'
***
*** Ver		Date		Author				Change
*** 1.0		01/10/18	Jonathan Kehayias
*** 1.1		08/10/18	Alex Stuart			Added event to track page split count on an index basis	
***
******************************************************************************************************/

USE master
GO

/***
Create session to track page splits at database level
***/
CREATE EVENT SESSION [TrackPageSplits]
ON SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT - page split operation
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'database_id');
GO
        
-- Start Event Session
ALTER EVENT SESSION [TrackPageSplits]
ON SERVER
STATE = START
GO

-- View results
SELECT 
    n.value('(value)[1]', 'bigint') AS database_id,
    DB_NAME(n.value('(value)[1]', 'bigint')) AS database_name,
    n.value('(@count)[1]', 'bigint') AS split_count
FROM
(SELECT CAST(target_data as XML) target_data
 FROM sys.dm_xe_sessions AS s 
 JOIN sys.dm_xe_session_targets t
     ON s.address = t.event_session_address
 WHERE s.name = 'TrackPageSplits'
  AND t.target_name = 'histogram' ) as tab
CROSS APPLY target_data.nodes('HistogramTarget/Slot') as q(n)

-- Drop session
DROP EVENT SESSION [TrackPageSplits]
ON SERVER



/***
Create session to track page splits at index level on a specified DB
***/
CREATE EVENT SESSION [TrackPageSplitsOnDB]
ON SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT - page split operation
	AND database_id = 9	-- Set specific DB here
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'alloc_unit_id');
GO

-- Start Event Session
ALTER EVENT SESSION [TrackPageSplitsOnDB]
ON SERVER
STATE = START
GO

-- View results
SELECT results.allocation_unit_id, so.name, results.split_count
FROM
	(SELECT 
		n.value('(value)[1]', 'bigint') AS allocation_unit_id,
		n.value('(@count)[1]', 'bigint') AS split_count
	FROM
		(SELECT CAST(target_data as XML) target_data
		 FROM sys.dm_xe_sessions AS s 
		 INNER JOIN sys.dm_xe_session_targets t
			ON s.[address] = t.event_session_address
		 WHERE s.name = 'TrackPageSplitsOnDB'
		 AND t.target_name = 'histogram' ) AS tab
	CROSS APPLY target_data.nodes('HistogramTarget/Slot') AS q(n) ) results
INNER JOIN sys.allocation_units sau
	ON results.allocation_unit_id = sau.allocation_unit_id
INNER JOIN sys.partitions sp
	ON sau.container_id = sp.[partition_id]
INNER JOIN sys.objects so
	ON sp.[object_id] = so.[object_id]

-- Drop session
DROP EVENT SESSION [TrackPageSplitsOnDB]
ON SERVER
