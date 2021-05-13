/*****************************************************************************************************
*** Simple AG Blocking Framework
***
***	A basic script to check an AG for blocking at instance-level and send an email alert if found.
*** First checks local replica state and only proceeds if in Primary role.
*** Assumes only one AG exists on server.
***
*** Ver		Date		Author			Comment
*** 1.0		18/09/19	Alex Stuart		Initial version
***
*******************************************************************************************************/

USE master
GO

DECLARE @hadr_role INT = 0;

SELECT @hadr_role = [role]
FROM sys.dm_hadr_availability_replica_states
WHERE is_local = 1

IF @hadr_role = 1
BEGIN

	DECLARE @sql VARCHAR(8000);

	SET @sql = '
DECLARE @blockedsessions_1 INT = 0;
DECLARE @blockedsessions_2 INT = 0;
DECLARE @blockedsessions_3 INT = 0;
DECLARE @blockedsessions_4 INT = 0;

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

WAITFOR DELAY ''00:00:10''

SELECT @blockedsessions_4 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

IF(@blockedsessions_1 <> 0 AND @blockedsessions_2 <> 0 AND @blockedsessions_3 <> 0 AND @blockedsessions_4 <> 0)
				BEGIN
					DECLARE @subject VARCHAR(200) = ''Blocking Alert - '' + @@SERVERNAME
					DECLARE @email_body VARCHAR(200) = ''Blocking has been detected on '' + @@SERVERNAME + '' - investigate immediately.''
					
					EXEC msdb.dbo.sp_send_dbmail  
					@profile_name = ''DBA'',  
					@recipients = ''team@company.com'',
					@subject = @subject,
					@body = @email_body
				END';

	EXEC(@sql);
END
