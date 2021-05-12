/**************************************************************************************
*** Check Restore History
*** 
*** Check backup restore history
***
*** Ver		Date		Author
*** 1.0		08/03/18	Alex Stuart
*** 
***************************************************************************************/
USE msdb
GO

SELECT *
FROM dbo.restorehistory
ORDER BY restore_date DESC
