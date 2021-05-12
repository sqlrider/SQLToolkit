/***********************************************************************************************************************************
*** CheckDB Solution Deployment Script
***
*** Deploys tables and stored procedures for CheckDB Solution
***
*** Ver		Date		Author			Changes
*** 1.0		02/10/18	Alex Stuart
*** 1.1		03/10/18	Alex Stuart		Added handling for fatal errors such as 211 which cause CHECKDB to terminate
*** 1.2		24/10/18	Alex Stuart		Added parameters for DATA_PURITY and PHYSICAL_ONLY checks
*** 1.3		24/10/18	Alex Stuart		Added code in comments at end of script to use in a job to check all databases on server
*** 1.4		02/11/18	Alex Stuart		Changed code to assume DBA tables exist instead of drop+recreate
***
************************************************************************************************************************************/

USE DBA
GO

-- Create Audit table
-- This table records the database, date and overall result (OK or errors) of the CHECKDB
IF OBJECT_ID('dbo.CheckDBAudit', 'U') IS NULL
BEGIN 
	CREATE TABLE dbo.CheckDBAudit
	(
		[Database] NVARCHAR(128),
		[Date] DATETIME,
		Duration VARCHAR(9),
		Info VARCHAR(500)
	)

	CREATE CLUSTERED INDEX cix_CheckDBAudit_Date_Database ON dbo.CheckDBAudit ([Date] DESC, [Database] ASC)

	PRINT 'Audit table created'
END
ELSE
BEGIN
	PRINT 'Table dbo.CheckDBAudit already exists. Skipping...';
END

-- Create error log table
-- This table records any pertinent error data from the CHECKDB output for any databases that showed errors
IF OBJECT_ID('dbo.CheckDBErrors', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.CheckDBErrors
	(
		[Database] NVARCHAR(128),
		[Date] DATETIME,
		[Error] INT,
		[Level] INT,
		[State] INT,
		[MessageText] VARCHAR(7000),
		[RepairLevel] VARCHAR(22),
		[ObjectID] BIGINT,
		[IndexID] INT
	);

	CREATE CLUSTERED INDEX cix_CheckDBErrors_Date_Database ON dbo.CheckDBErrors ([Date] DESC, [Database] ASC)

	PRINT 'Error table created'
END
ELSE
BEGIN
	PRINT 'Table dbo.CheckDBErrors already exists. Skipping...';
END


-- Create procedure
IF OBJECT_ID('dbo.CheckDB', 'P') IS NOT NULL
	DROP PROCEDURE dbo.CheckDB;
GO

CREATE PROCEDURE [dbo].[CheckDB]
@dbname VARCHAR(128),
@physical_only INT = 0,
@data_purity INT = 0

AS
BEGIN

/***************************************************************************************************************************
*** dbo.CheckDB
*** 
*** Runs DBCC CHECKDB on database specified by parameter @dbname
***
*** Ver		Date		Author
*** 1.0		02/10/18	Alex Stuart
*** 1.1		03/10/18	Alex Stuart		Added handling for fatal errors such as 211 which cause CHECKDB to terminate
*** 1.2		24/10/18	Alex Stuart		Added parameters for DATA_PURITY and PHYSICAL_ONLY checks
*** 1.3     02/11/18	Alex Stuart		Added custom message for if database is in an unreadable secondary AG replica
*****************************************************************************************************************************/

SET NOCOUNT ON;

DECLARE @errormsg VARCHAR(200);
DECLARE @option VARCHAR(15);
DECLARE @starttime DATETIME;
DECLARE @duration_total_seconds INT;
DECLARE @duration_hours INT;
DECLARE @duration_minutes INT;
DECLARE @duration_seconds INT;
DECLARE @duration VARCHAR(9);

BEGIN TRY
	-- Ensure database exists
	IF NOT EXISTS (SELECT name
				   FROM sys.databases
				   WHERE name = @dbname)
	BEGIN
		SET @errormsg = 'Database ' + @dbname + ' doesn''t exist.';
		RAISERROR(@errormsg, 16, 1);
	END


	-- Ensure valid parameter values and combination of parameters
	IF @data_purity NOT IN (0, 1)
	BEGIN
		SET @errormsg = '@data_purity parameter must be 0 or 1.';
		RAISERROR(@errormsg, 16, 1);
	END

	IF @physical_only NOT IN (0, 1)
	BEGIN
		SET @errormsg = '@physical_only parameter must be 0 or 1.';
		RAISERROR(@errormsg, 16, 1);
	END

	IF @data_purity + @physical_only = 2
	BEGIN
		SET @errormsg = 'Cannot use both PHYSICAL_ONLY and DATA_PURITY options.';
		RAISERROR(@errormsg, 16, 1);
	END

	-- Create temp table to hold results  
	CREATE TABLE #CHECKDB ([Error] INT, [Level] INT, [State] INT, [MessageText] VARCHAR(7000), [RepairLevel] VARCHAR(22), [Status] INT, [DbId] INT, [DbFragID] INT,
							   [ObjectID] INT, [IndexId] INT, [PartitionId] BIGINT, [AllocUnitId] BIGINT, [RidDbId] INT, RidPruID INT, [File] INT, [Page] BIGINT, [Slot] INT,
							   [RefDbID] INT, [RefPruId] INT, [RefFile] INT, [RefPage] BIGINT, [RefSlot] INT, [Allocation] INT);

	-- Set version variable
	DECLARE @version INT;
	SET @version = CAST(REPLACE(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)),1,2), '.', '') AS INT);

	-- Create SQL statement
	SELECT @option = CASE
						  WHEN @physical_only = 1 THEN 'PHYSICAL_ONLY, '
						  WHEN @data_purity = 1 THEN 'DATA_PURITY, '
						  ELSE ''
					 END;

	DECLARE @sql VARCHAR(400);
	SET @sql = 'USE [' + @dbname + '];
				DBCC CHECKDB WITH ' + @option + 'TABLERESULTS;';


	-- Set start time
	SET @starttime = GETDATE();

	-- Check version - output from 2012+ (v11+) has extra columns DbFragId, RidDbId, RidPruId, RefDbID, RefPruId
	-- so requires seperate insert statement
	IF @version >= 11
	BEGIN	
		-- Run check and insert results into temp table
		INSERT INTO #CHECKDB ([Error], [Level], [State], [MessageText], [RepairLevel], [Status], [DbId], [DbFragID],
							   [ObjectID], [IndexId], [PartitionId], [AllocUnitId], [RidDbId], [RidPruID], [File], [Page], [Slot], 
							   [RefDbID], [RefPruId], [RefFile], [RefPage], [RefSlot], [Allocation])
		EXEC (@sql);

		-- Set finish time and calculate duration
		SET @duration_total_seconds = DATEDIFF(SECOND, @starttime, GETDATE());
		SET @duration_hours = @duration_total_seconds / 60 / 60;
		SET @duration_minutes = (@duration_total_seconds - (@duration_hours * 60 * 60)) / 60;
		SET @duration_seconds = @duration_total_seconds - (@duration_hours * 60 * 60) - (@duration_minutes * 60);
		SET @duration = CAST(@duration_hours AS VARCHAR(2)) + 'h' + CAST(@duration_minutes AS VARCHAR(2)) + 'm' + CAST(@duration_seconds AS VARCHAR(2)) + 's';

		-- If no errors, insert OK record into audit table
		IF EXISTS (SELECT *
				   FROM #CHECKDB
				   WHERE Error = '8989' AND MessageText LIKE 'CHECKDB found 0 allocation errors and 0 consistency errors in database%')
		BEGIN
			INSERT INTO dbo.CheckDBAudit ([Database], [Date], Duration, Info)
			VALUES (@dbname, @starttime, @duration, 'No errors found.');
		END

		-- If errors, insert output into errors table and an error record into audit table
		IF EXISTS (SELECT *
				   FROM #CHECKDB
				   WHERE [Level] > 10)
		BEGIN
			INSERT INTO dbo.CheckDBErrors ([Database], [Date], [Error], [Level], [State], [MessageText], [RepairLevel], [ObjectID], [IndexID])
			SELECT @dbname, @starttime, [Error], [Level], [State], [MessageText], [RepairLevel], [ObjectID], [IndexID]
			FROM #CHECKDB
			WHERE [Level] > 10;
	
			INSERT INTO dbo.CheckDBAudit ([Database], [Date], Duration, [Info])
			VALUES (@dbname, @starttime, @duration, 'Errors found. See dbo.CheckDBErrors for output.');
		END
	END
	ELSE -- versions 2000/2005/2008
	BEGIN
		-- Run check and insert results into temp table
		INSERT INTO #CHECKDB ([Error], [Level], [State], [MessageText], [RepairLevel], [Status], [DbId], [ObjectID],
							   [IndexId], [PartitionId], [AllocUnitId], [File], [Page], [Slot], [RefFile], [RefPage], [RefSlot],
							   [Allocation])
		EXEC (@sql);

		-- Set finish time and calculate duration
		SET @duration_total_seconds = DATEDIFF(SECOND, @starttime, GETDATE());
		SET @duration_hours = @duration_total_seconds / 60 / 60;
		SET @duration_minutes = (@duration_total_seconds - ((@duration_total_seconds / 60 / 60) * 60 * 60)) / 60;
		SET @duration_seconds = @duration_total_seconds - ((@duration_total_seconds / 60 / 60) * 60 * 60) - (((@duration_total_seconds - ((@duration_total_seconds / 60 / 60) * 60 * 60)) / 60) * 60);
		SET @duration = CAST(@duration_hours AS VARCHAR(2)) + 'h' + CAST(@duration_minutes AS VARCHAR(2)) + 'm' + CAST(@duration_seconds AS VARCHAR(2)) + 's';

		-- If no errors, insert OK record into audit table
		IF EXISTS (SELECT *
				   FROM #CHECKDB
				   WHERE Error = '8989' AND MessageText LIKE 'CHECKDB found 0 allocation errors and 0 consistency errors in database%')
		BEGIN
			INSERT INTO dbo.CheckDBAudit ([Database], [Date], Duration, Info)
			VALUES (@dbname, @starttime, @duration, 'No errors found.');
		END

		-- If errors, insert output into errors table and an error record into audit table
		IF EXISTS (SELECT *
				   FROM #CHECKDB
				   WHERE [Level] > 10)
		BEGIN
			INSERT INTO dbo.CheckDBErrors ([Database], [Date], [Error], [Level], [State], [MessageText], [RepairLevel], [ObjectID], [IndexID])
			SELECT @dbname, @starttime, [Error], [Level], [State], [MessageText], [RepairLevel], [ObjectID], [IndexID]
			FROM #CHECKDB
			WHERE [Level] > 10;
	
			INSERT INTO dbo.CheckDBAudit ([Database], [Date], Duration, [Info])
			VALUES (@dbname, @starttime, @duration, 'Errors found. See dbo.CheckDBErrors for output.');
		END
	END

END TRY
BEGIN CATCH

	DECLARE @ErrorNumber INT, @ErrorMessage NVARCHAR(MAX), @info VARCHAR(500);
	SELECT @ErrorNumber = ERROR_NUMBER(), @ErrorMessage = ERROR_MESSAGE();

	SET @info = CASE WHEN @ErrorNumber = 211 THEN 'Error 211 - ''Possible schema corruption. Run DBCC CHECKCATALOG''. System database may be corrupt.'
					 WHEN @ErrorNumber = 976 THEN 'Skipped - database is in an AG as an unreadable secondary.'
					 ELSE 'Error ' + CAST(@ErrorNumber AS VARCHAR(6)) + ' - ''' + @ErrorMessage + '''.'
			    END;

	INSERT INTO dbo.CheckDBAudit ([Database], [Date], Duration, [Info])
	VALUES (@dbname, GETDATE(), NULL, @info);

END CATCH

--- Cleanup
DELETE 
FROM DBA.dbo.CheckDBAudit
WHERE [Date] < DATEADD(MONTH, -3, GETDATE())

DELETE 
FROM DBA.dbo.CheckDBErrors
WHERE [Date] < DATEADD(MONTH, -1, GETDATE())


END
GO

PRINT 'Procedure created'
GO

/*
DECLARE @jobscript VARCHAR(MAX)
SET @jobscript = "DECLARE dbnames CURSOR 
FOR
	SELECT d.name
	FROM sys.databases d
	WHERE d.state_desc = 'ONLINE'
	AND d.name <> 'tempdb'
	ORDER BY d.name ASC

DECLARE @dbname VARCHAR(256);

OPEN dbnames

FETCH NEXT FROM dbnames INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC dbo.CheckDB @dbname;

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames"

EXECUTE msdb.dbo.sp_add_job @job_name = 'DBA - CheckDB', @description = 'Runs dbo.CheckDB on all databases', @category_name = '[DBCC]', @owner_login_name = 'sa'
EXECUTE msdb.dbo.sp_add_jobstep @job_name = 'DBA - CheckDB', @step_name = 'Run CheckDB', @subsystem = 'TSQL', @command = @jobscript, @database_name = 'DBA'
*/



/*** The script below is included for use in a SQL Server Agent Job to check all databases on the server the solution is deployed to. 

DECLARE dbnames CURSOR 
FOR
	SELECT d.name
	FROM sys.databases d
	WHERE d.state_desc = 'ONLINE'
	AND d.name <> 'tempdb'
	ORDER BY d.name ASC

DECLARE @dbname VARCHAR(256);

OPEN dbnames

FETCH NEXT FROM dbnames INTO @dbname

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC dbo.CheckDB @dbname;

	FETCH NEXT FROM dbnames INTO @dbname
END

CLOSE dbnames;
DEALLOCATE dbnames

***/

