/*******************************************************************************************************************
*** Querying Profiler Trace
*** 
*** Load a Profiler trace into a table to query textdata efficiently.
***
*** Ver		Date		Author
*** 1.0		01/02/18	Alex Stuart
*** 
********************************************************************************************************************/


USE [databasename]
GO

SELECT *
INTO dbo.tablename
FROM fn_trace_gettable('D:\Traces\filename.trc', default)


-- Convert TextData column to VARCHAR so it can be indexed
ALTER TABLE dbo.tablename
ALTER COLUMN TextData VARCHAR(MAX)

CREATE NONCLUSTERED INDEX idx_tablename_TextData
ON dbo.tablename (TextData)

/*

SELECT *
FROM dbo.tablename
WHERE duration > 1000000
ORDER BY Duration DESC, Reads DESC

SELECT MIN(Duration) AS 'MinDuration', AVG(Duration) AS 'AvgDuration', MAX(Duration) AS 'MaxDuration',
		MIN(Reads) AS 'MinReads', AVG(Reads) AS 'AvgReads', MAX(Reads) AS 'MaxReads',
		MIN(CPU) AS 'MinCPU', AVG(CPU) AS 'AvgCPU', MAX(CPU) AS 'MaxCPU'
FROM dbo.tablename
WHERE Textdata LIKE 'text you're looking for%'

*/

DROP TABLE dbo.tablename
