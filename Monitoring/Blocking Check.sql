/*****************************************************************************************************
*** Blocking Check
***
***	Script to check for blocking and send an email alert if found.
*** First checks if DB is in an AG and only proceeds if in Primary role.
*** Assumes only one AG exists on server and that the DB specified is included in the AG. 
***
*** Ver		Date		Author			Comment
*** 1.0		12/06/19	Alex Stuart
*** 1.1		18/09/19	Alex Stuart		Changed to check for sustained blocking over 30 seconds
***
*******************************************************************************************************/

USE master
GO

DECLARE @hadr_role INT = 1;

SELECT @hadr_role = [role]
FROM sys.dm_hadr_availability_replica_states
WHERE is_local = 1

IF @hadr_role = 1
BEGIN

	DECLARE @sql VARCHAR(8000);

	-- Replace database name in USE statement
	SET @sql = 'USE [databasename];

DECLARE @blockedsessions_1 INT = 0;
DECLARE @blockedsessions_2 INT = 0;
DECLARE @blockedsessions_3 INT = 0;

DECLARE @email_body VARCHAR(200) = ''Blocking has been detected on '' + @@SERVERNAME + '' '' + DB_NAME(DB_ID()) + '' database - investigate immediately.''


SELECT @blockedsessions_1 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

WAITFOR DELAY ''00:00:10''

SELECT @blockedsessions_2 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

WAITFOR DELAY ''00:00:10''

SELECT @blockedsessions_3 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

IF(@blockedsessions_1 <> 0 AND @blockedsessions_2 <> 0 AND @blockedsessions_3 <> 0)
				BEGIN
					EXEC msdb.dbo.sp_send_dbmail  
					@profile_name = ''DBA'',  
					@recipients = ''team@company.com'',
					@subject = ''Blocking Alert'',
					@body = @email_body
				END';

	EXEC(@sql);
END
