/*************************************************************************************************
*** Query Default Trace
*** 
*** Get path of and query the default trace, if enabled.
***
*** Ver		Date		Author
*** 1.0		14/03/19	Alex Stuart
*** 
*************************************************************************************************/

USE master
GO

-- Check default trace enabled - value should be 1
EXEC sp_configure 'default trace enabled';

-- Get path of default trace
SELECT *
FROM sys.fn_trace_getinfo(1);

-- paste filename here

-- Get event IDs to look for - for example, data/log autogrowths = 92 and 93 respectively
SELECT *
FROM sys.trace_events e
WHERE name LIKE '%grow%';

-- Interrogate default trace
SELECT TE.name, tr.DatabaseName, tr.FileName, tr.StartTime, tr.EndTime
FROM sys.fn_trace_gettable('D:\directory\filename.trc', DEFAULT) TR
INNER JOIN sys.trace_events TE
ON TR.EventClass = TE.trace_event_id
WHERE TR.EventClass IN (92, 93)
ORDER BY StartTime DESC;
