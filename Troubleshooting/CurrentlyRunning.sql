/**************************************************************************************
*** CurrentlyRunning
*** 
*** Display queries that are currently running and their associated stats
***
*** Ver		Date		Author
*** 1.0		12/06/19	Alex Stuart
*** 
***************************************************************************************/

SELECT des.session_id,
	des.host_name,
	des.program_name,
	des.login_name,
	des.[status],
	der.start_time,
	der.[status],
	der.database_id,
	der.blocking_session_id,
	der.wait_type,
	der.wait_time,
	der.open_transaction_count,
	der.cpu_time,
	der.total_elapsed_time,
	der.reads,
	der.logical_reads,
	der.writes,
	der.command,
	der.percent_complete,
--	der.query_plan_hash,
	est.text
FROM sys.dm_exec_sessions des
INNER JOIN sys.dm_exec_requests der
	ON des.session_id = der.session_id
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) est
