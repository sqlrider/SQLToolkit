/***************************************************************************************************************************
*** Delete Execution Logs
*** 
*** Batch delete SSIS package execution logs from SSISDB internal tables (causes cascading deletes to referencing tables)
*** Useful if SSIS maintenance procedure is getting stuck due to volume of backlog or concurrently-executing jobs.
*** Adjust batch size and delay pending results of testing if possible. Template batch size of 1 was used for an extremely
*** large project with ~100 complicated packages, can likely be much higher for typical projects.
***
*** Ver		Date		Author
*** 1.0		14/09/18	Alex Stuart
*** 
****************************************************************************************************************************/


DECLARE @i INT
DECLARE @r INT
SET @i = 1;

WHILE (@i > 0)
BEGIN
	DELETE TOP (1)
	FROM internal.operations
	WHERE object_name = 'project name'
	AND operation_id < 100000

	SET @i = @@ROWCOUNT

	SELECT @R = COUNT(operation_id)
	FROM internal.operations
	WHERE object_name = 'project name'
	AND operation_id < 100000

	SELECT CAST(@R AS VARCHAR(MAX)) + ' rows remaining. ' + CAST(GETDATE() AS VARCHAR(MAX))

	WAITFOR DELAY '00:00:05'
END
