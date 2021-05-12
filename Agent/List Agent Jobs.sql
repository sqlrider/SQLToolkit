/*********************************************
*** List SQL Agent Jobs
*** 
*** Lists active SQL Agent jobs and next scheduled run-times.
***
*** Ver		Date		Author
*** 1.0		05/02/19	Alex Stuart
*** 
**********************************************/


USE msdb
GO

SELECT j.job_id, j.name, j.[description], ja.next_scheduled_run_date
FROM dbo.sysjobs j 
INNER JOIN dbo.sysjobactivity ja
	ON j.job_id = ja.job_id
WHERE j.[enabled] = 1
AND ja.next_scheduled_run_date > GETDATE()
