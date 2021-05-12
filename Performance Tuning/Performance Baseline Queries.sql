/*********************************************************************************************
*** Performance Baseline Queries
***
*** A bunch of performance baselining queries interrogating various DMVs and Perfmon counters.
***
*** Ver		Date		Author
*** 1.0		20/09/18	Alex Stuart (I think!!)
***
***********************************************************************************************/

USE master
GO

--- CPU
-- CPU usage
DECLARE @ts_now BIGINT   
SELECT @ts_now = ms_ticks
FROM sys.dm_os_sys_info

SELECT Total_CPU_Usage
FROM
(
	SELECT TOP 1
	  record_id,
	  dateadd (ms, (y.[timestamp] -@ts_now), GETDATE()) as EventTime,
	  SystemIdle Idle,
	  SQLProcessUtilization [SQL],
	  100 - SystemIdle - SQLProcessUtilization as OtherProcessUtilization,
	  0 + SQLProcessUtilization + (100 - SystemIdle - SQLProcessUtilization) as Total_CPU_usage
	FROM
	(
		SELECT record.value('(./Record/@id)[1]', 'int') as record_id,
			   record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,
			   record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization,
			   TIMESTAMP   
		FROM
		(   
			SELECT TIMESTAMP,
				   CONVERT(XML, record) AS record
			FROM sys.dm_os_ring_buffers   
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'   
			AND record LIKE '%<SystemHealth>%'
		) AS x   
	) AS y
ORDER BY record_id DESC
) AS z


---- Memory

-- PLE
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager'
AND counter_name = 'Page life expectancy'

-- Lazy Writes
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager'
AND counter_name = 'Lazy writes/sec'

-- Free list stalls
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager'
AND counter_name = 'Free list stalls/sec'

-- Memory Grants Outstanding
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Memory Manager'
AND counter_name = 'Memory Grants Pending'

-- Checkpoint pages/sec
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager'
AND counter_name = 'Checkpoint pages/sec'

-- Stolen server memory
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Memory Manager'
AND counter_name = 'Stolen Server Memory (KB)'

-- Lock Blocks
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Memory Manager'
AND counter_name = 'Lock Blocks'



--- Indexes
-- Page Splits
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Access Methods'
AND counter_name = 'Page Splits/sec'



-- Batch times
SELECT [object_name], counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Batch Resp Statistics' 
AND instance_name = 'Elapsed Time:Requests'


--- Disk
-- Page Reads/sec
SELECT [object_name], counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager' 
AND counter_name = 'Page reads/sec'

-- Page writes/sec
SELECT [object_name], counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:Buffer Manager' 
AND counter_name = 'Page writes/sec'


--- Query Processing
-- Compilations/sec
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:SQL Statistics'
AND counter_name = 'SQL Compilations/sec'
ORDER BY [object_name] ASC, counter_name ASC

-- Reompilations/sec
SELECT *
FROM sys.dm_os_performance_counters
WHERE [object_name] = 'SQLServer:SQL Statistics'
AND counter_name = 'SQL Re-Compilations/sec'
ORDER BY [object_name] ASC, counter_name ASC


--- Wait Statistics




SELECT *
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Wait Statistics'
ORDER BY [object_name] ASC, counter_name ASC


SELECT *
FROM sys.dm_os_sys_info

SELECT *
FROM sys.dm_io_virtual_file_stats(DB_ID('databasename'), NULL)
