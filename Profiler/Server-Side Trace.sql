/****************************************************************************************************
*** Server-Side Trace
*** 
*** A skeleton script for creating a server-side Profiler trace (monitoring column use example)
***
*** Ver		Date		Author
*** 1.0		21/03/19	Alex Stuart
*** 
*****************************************************************************************************/

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize BIGINT

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

SET @maxfilesize = 50

exec @rc = sp_trace_create @TraceID output,
							@options = 2,
							@tracefile = N'L:\Trace\MonitorUsage', 
							@maxfilesize = @maxfilesize,
							@stoptime = NULL,
							@filecount = 10
if (@rc != 0) goto error



-- Set the events
declare @on bit
set @on = 1

-- RPC Complete
/*
exec sp_trace_setevent @TraceID, 10, 1, @on	-- TextData (query text)
exec sp_trace_setevent @TraceID, 10, 2, @on -- BinaryData
exec sp_trace_setevent @TraceID, 10, 3, @on -- DatabaseID
exec sp_trace_setevent @TraceID, 10, 6, @on -- NTUserName
exec sp_trace_setevent @TraceID, 10, 10, @on -- ApplicationName
exec sp_trace_setevent @TraceID, 10, 11, @on -- LoginName
exec sp_trace_setevent @TraceID, 10, 12, @on -- SPID
exec sp_trace_setevent @TraceID, 10, 14, @on -- StartTime
exec sp_trace_setevent @TraceID, 10, 15, @on -- EndTime
*/

-- Batch Complete
/*
exec sp_trace_setevent @TraceID, 12, 1, @on -- TextData (query)
exec sp_trace_setevent @TraceID, 12, 3, @on -- DatabaseID
exec sp_trace_setevent @TraceID, 12, 6, @on -- NTUserName
exec sp_trace_setevent @TraceID, 12, 10, @on -- ApplicationName
exec sp_trace_setevent @TraceID, 12, 11, @on -- LoginName
exec sp_trace_setevent @TraceID, 12, 12, @on -- SPID
exec sp_trace_setevent @TraceID, 12, 14, @on -- StartTime
exec sp_trace_setevent @TraceID, 12, 15, @on -- EndTime
*/

-- Statement Complete
exec sp_trace_setevent @TraceID, 41, 1, @on -- TextData (query)
exec sp_trace_setevent @TraceID, 41, 3, @on -- DatabaseID
exec sp_trace_setevent @TraceID, 41, 6, @on -- NTUserName
exec sp_trace_setevent @TraceID, 41, 10, @on -- ApplicationName
exec sp_trace_setevent @TraceID, 41, 11, @on -- LoginName
exec sp_trace_setevent @TraceID, 41, 12, @on -- SPID
exec sp_trace_setevent @TraceID, 41, 14, @on -- StartTime
exec sp_trace_setevent @TraceID, 41, 15, @on -- EndTime

-- Stored Proc Complete
/*
exec sp_trace_setevent @TraceID, 43, 1, @on -- TextData (query)
exec sp_trace_setevent @TraceID, 43, 3, @on -- DatabaseID
exec sp_trace_setevent @TraceID, 43, 6, @on -- NTUserName
exec sp_trace_setevent @TraceID, 43, 10, @on -- ApplicationName
exec sp_trace_setevent @TraceID, 43, 11, @on -- LoginName
exec sp_trace_setevent @TraceID, 43, 12, @on -- SPID
exec sp_trace_setevent @TraceID, 43, 14, @on -- StartTime
exec sp_trace_setevent @TraceID, 43, 15, @on -- EndTime
*/

-- Stored Proc Statement Completed
exec sp_trace_setevent @TraceID, 45, 1, @on -- TextData (query)
exec sp_trace_setevent @TraceID, 45, 3, @on -- DatabaseID
exec sp_trace_setevent @TraceID, 45, 6, @on -- NTUserName
exec sp_trace_setevent @TraceID, 45, 10, @on -- ApplicationName
exec sp_trace_setevent @TraceID, 45, 11, @on -- LoginName
exec sp_trace_setevent @TraceID, 45, 12, @on -- SPID
exec sp_trace_setevent @TraceID, 45, 14, @on -- StartTime
exec sp_trace_setevent @TraceID, 45, 15, @on -- EndTime



-- Set the Filters
declare @intfilter int
declare @varcharfilter NVARCHAR(256);

SET @varcharfilter = '%filter text here%'

-- Ignore Profiler noise
exec sp_trace_setfilter @TraceID, 10, 0, 7, N'%SQL Server Profiler%'

-- Set main filters here
exec sp_trace_setfilter @traceid = @TraceID,
			@columnid = 1,				-- TextData
			@logical_operator = 0,			-- AND
			@comparison_operator = 6,		-- LIKE
			@value = @varcharfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
