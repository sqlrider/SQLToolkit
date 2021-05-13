/*****************************************************************************************************
*** Blocking Check
***
*** A simple framework to check for blocking and send an email alert if found. 
***
*** Ver		Date		Author			Comment
*** 1.0		12/06/19	Alex Stuart
***
*******************************************************************************************************/

USE master
GO

DECLARE @blockedsessions_1 INT = 0;
DECLARE @blockedsessions_2 INT = 0;
DECLARE @blockedsessions_3 INT = 0;
DECLARE @blockedsessions_4 INT = 0;

SELECT @blockedsessions_1 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

WAITFOR DELAY '00:00:10'

SELECT @blockedsessions_2 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

WAITFOR DELAY '00:00:10'

SELECT @blockedsessions_3 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

WAITFOR DELAY '00:00:10'

SELECT @blockedsessions_4 = COUNT(*)
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0

IF(@blockedsessions_1 <> 0 AND @blockedsessions_2 <> 0 AND @blockedsessions_3 <> 0 AND @blockedsessions_4 <> 0)
BEGIN
    DECLARE @subject VARCHAR(200) = 'Blocking Alert - ' + @@SERVERNAME
    DECLARE @email_body VARCHAR(200) = 'Blocking has been detected on ' + @@SERVERNAME + ' - investigate immediately.'

    EXEC msdb.dbo.sp_send_dbmail  
     @profile_name = 'DBA',  
     @recipients = 'team@company.com',
     @subject = @subject,
     @body = @email_body
END
