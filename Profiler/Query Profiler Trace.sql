/*******************************************************************************************************************
*** Querying Profiler Trace
*** 
*** Query/load a Profiler trace into a table to query plans.
*** Uncomment INTO line and run step-by-step to load into table then drop.
***
*** Ver		Date		Author
*** 1.0		01/02/18	Alex Stuart
*** 
********************************************************************************************************************/
USE DBA
GO

SELECT *
-- INTO dbo.TraceData
FROM fn_trace_gettable('L:\Trace\MonitorUsage.trc', default)

ALTER TABLE dbo.TraceData
ALTER COLUMN TextData VARCHAR(MAX)

CREATE CLUSTERED INDEX cix_TraceData_StartTime
ON dbo.TraceData (StartTime)

CREATE NONCLUSTERED INDEX idx_TraceData_TextData
ON dbo.TraceData (TextData)

/*

SELECT *
FROM dbo.TraceData
WHERE duration > 1000000
ORDER BY Duration DESC, Reads DESC

SELECT MIN(Duration) AS 'MinDuration', AVG(Duration) AS 'AvgDuration', MAX(Duration) AS 'MaxDuration',
		MIN(Reads) AS 'MinReads', AVG(Reads) AS 'AvgReads', MAX(Reads) AS 'MaxReads',
		MIN(CPU) AS 'MinCPU', AVG(CPU) AS 'AvgCPU', MAX(CPU) AS 'MaxCPU'
FROM dbo.TraceData
WHERE Textdata LIKE '%filter text here%'

*/

DROP TABLE dbo.TraceData
