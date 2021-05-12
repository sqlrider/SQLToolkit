/*******************************************************************************************************************
*** Extended Events - Table Activity
*** 
*** An Extended Events session to trace activity on a given table
***
*** Ver		Date		Author
*** 1.0		15/01/19	Alex Stuart
*** 
********************************************************************************************************************/



CREATE EVENT SESSION [SatsumaCmaDataFeedAudit]																	-- Session name goes here
ON SERVER 
ADD EVENT sqlserver.rpc_completed
	(
		SET collect_statement=(1)
		ACTION(sqlserver.client_app_name,
			   sqlserver.client_hostname,
			   sqlserver.database_id,
			   sqlserver.session_id,
		       sqlserver.session_nt_username,
		       sqlserver.sql_text)
		WHERE ([package0].[equal_uint64]([sqlserver].[database_id],(25))										-- database_id goes here
				AND [sqlserver].[like_i_sql_unicode_string]([statement],N'%TableName%'))						-- table name goes here
	),
ADD EVENT sqlserver.sql_statement_completed
	(
		ACTION(sqlserver.client_app_name,
			   sqlserver.client_hostname,
			   sqlserver.database_id,
			   sqlserver.session_id,
			   sqlserver.session_nt_username,
			   sqlserver.sql_text)
		WHERE ([package0].[equal_uint64]([sqlserver].[database_id],(25))										-- database_id goes here
			   AND [sqlserver].[like_i_sql_unicode_string]([statement],N'%TableName%'))							-- table name goes here
	) 
ADD TARGET package0.event_file
(
	SET filename = N'F:\DBA\XE\filename.xel')																	-- File name goes here
	WITH (MAX_MEMORY=4096 KB,
		  EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
		  MAX_DISPATCH_LATENCY = 30 SECONDS,
		  MAX_EVENT_SIZE = 0 KB,
		  MEMORY_PARTITION_MODE = NONE,
		  TRACK_CAUSALITY=OFF,
		  STARTUP_STATE=ON)
GO


