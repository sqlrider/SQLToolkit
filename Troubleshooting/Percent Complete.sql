/*************************************************************************************************
*** Percent Complete
*** 
*** List elapsed and projected completion time of a command where this information is provided,
*** for example backups, restores, CHECKDB.
***
*** Ver		Date		Author
*** 1.0		14/03/19	Alex Stuart
*** 
*************************************************************************************************/
USE master
GO

SELECT percent_complete as 'Percent Complete',
	start_time as 'Start',
	[status] as 'Status',
	command as 'Command',
	estimated_completion_time as 'ETA',
 (estimated_completion_time / 1000/60 /60/ 24) AS 'Days',
 ((estimated_completion_time / 1000/60 /60) % 24) AS 'Hours',
 ((estimated_completion_time / 1000/60 ) % 60) AS 'Mins',
 ((estimated_completion_time / 1000) % 60) AS 'Secs',
 total_elapsed_time as 'Total_Elapsed_Time',
 (total_elapsed_time / 1000/60 /60/ 24) AS 'Days',
 ((total_elapsed_time / 1000/60 /60) % 24) AS 'Hours',
 ((total_elapsed_time / 1000/60 ) % 60) AS 'Mins',
 ((total_elapsed_time / 1000) % 60) AS 'Seconds'
 FROM sys.dm_exec_requests
 --WHERE percent_complete > 0
 ORDER BY start_time DESC
