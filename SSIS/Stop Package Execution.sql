/**************************************************************************************
*** Stop Package Execution
*** 
*** Stop SSIS package execution.
***
*** Ver		Date		Author
*** 1.0		22/02/19	Alex Stuart
*** 
***************************************************************************************/

USE SSISDB
GO

-- Get execution_id from catalog.executions
SELECT *
FROM [catalog].executions
WHERE end_time IS NULL

DECLARE @exec_id INT
SET @exec_id = 99999 -- Set execution_id here					


-- Stop package execution
EXEC catalog.stop_operation @operation_id = @exec_id
