
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[usp_PurgeData] @PurgeDate DATETIME, @TableName SYSNAME, @Requestor NVARCHAR(50), @Approver NVARCHAR(50)
AS
BEGIN

SET NOCOUNT, XACT_ABORT ON

DECLARE @logmessage NVARCHAR(2048)
DECLARE @Executor NVARCHAR(40)

SET @Executor = SUSER_NAME()

SET @logmessage = 'Partition delete process initiated for table ' + @TableName + '. Requestor: ' + @Requestor + ', Approver: ' + @Approver + ', Executor: ' + @Executor
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

-- Check that table exists
	IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE [name] = @TableName)
	BEGIN
		SET @logmessage = 'Error: table ' + @TableName + ' does not exist. Exiting procedure'
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		RETURN -1
	END

-- Check that date is valid - prior to 6 years prior to the current financial year (current FY starts in preceding January, so count 6 whole years back from then)
	DECLARE @startofcurrentfinyear DATETIME
	DECLARE @6priorfinyears DATETIME
	DECLARE @validcutoff VARCHAR(23)

	SET @startofcurrentfinyear = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	SET @6priorfinyears = DATEADD(YEAR, -6, @startofcurrentfinyear)
	SET @validcutoff = CONVERT(VARCHAR,@6priorfinyears,121)

	SET @PurgeDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @PurgeDate), 0)
	PRINT '@PurgeDate rounded to start of month = ' + CONVERT(VARCHAR(23), @PurgeDate, 121)

	IF @PurgeDate <= @6priorfinyears
		PRINT 'Purge date is valid - less than or equal to ' + @validcutoff + ' - proceeding'
	ELSE
	BEGIN
		SET @logmessage = 'Error: @PurgeDate is invalid - higher than ' + @validcutoff + ' - exiting procedure.'
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		RETURN 
	END

-- Create staging table on same partition scheme
	IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'InvoicesPT_FG_Staging')
		DROP TABLE InvoicesPT_FG_Staging;

	CREATE TABLE dbo.InvoicesPT_FG_Staging
	(
		InvoiceID		INT IDENTITY(1,1) NOT NULL,
		InvoiceDate		DATETIME NOT NULL,
		InvoiceMonth	VARCHAR(10),
		InvoiceData		VARCHAR(50),
		CONSTRAINT pk_Staging_FG_InvoiceID PRIMARY KEY CLUSTERED (InvoiceID, InvoiceDate) ON ps_Monthly_FG(InvoiceDate)
	)

	CREATE NONCLUSTERED INDEX ncx_Staging_InvoicesPT_FG_Month ON dbo.InvoicesPT_FG_Staging (InvoiceMonth) ON ps_Monthly_FG(InvoiceDate)

	SET @logmessage = 'Staging table created successfully'
	PRINT @logmessage
	INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)


-- Check there are 0 rows in first partition
	DECLARE @first_partition_rowcount BIGINT

	SELECT @first_partition_rowcount = ps.row_count
	FROM sys.dm_db_partition_stats ps
	WHERE [object_id] = OBJECT_ID('InvoicesPT_FG')
	AND ps.index_id = 1
	AND ps.partition_number = 1

	IF @first_partition_rowcount <> 0
	BEGIN
		SET @logmessage = 'Error - first partition has rows. Investigate and remove before merging partitions.'
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		RETURN -1
	END


-- Check @purgedata boundary value exists 
	IF NOT EXISTS (SELECT 1 FROM sys.partitions p
					INNER JOIN sys.indexes i
						ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
					INNER JOIN sys.partition_schemes ps
						ON i.data_space_id = ps.data_space_id
					INNER JOIN sys.destination_data_spaces dds
						ON ps.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
					INNER JOIN sys.data_spaces ds2
						ON dds.data_space_id = ds2.data_space_id
					INNER JOIN sys.partition_functions pf
						ON ps.function_id = pf.function_id
					LEFT JOIN sys.partition_range_values prv
						ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
					WHERE OBJECT_NAME(p.[object_id]) = 'InvoicesPT_FG'
						AND p.index_id = 1
						AND prv.[value] < @purgedate)
	BEGIN
		SET @logmessage = 'Error - @PurgeDate is too old - does not exist as a monthly partition boundary in table'
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		RETURN -1
	END


-- Loop over partitions

BEGIN TRY

	DECLARE @partition_to_switch INT
	DECLARE @boundary_value DATETIME
	DECLARE @rows BIGINT

	DECLARE partition_numbers CURSOR LOCAL
	FOR
	SELECT p.partition_number, CONVERT(DATETIME, prv.[value]), p.[rows]
	FROM sys.partitions p
	INNER JOIN sys.indexes i
		ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
	INNER JOIN sys.partition_schemes ps
		ON i.data_space_id = ps.data_space_id
	INNER JOIN sys.destination_data_spaces dds
		ON ps.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
	INNER JOIN sys.data_spaces ds2
		ON dds.data_space_id = ds2.data_space_id
	INNER JOIN sys.partition_functions pf
		ON ps.function_id = pf.function_id
	LEFT JOIN sys.partition_range_values prv
		ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
	WHERE OBJECT_NAME(p.[object_id]) = 'InvoicesPT_FG'
		AND p.index_id = 1
		AND prv.[value] < @purgedate
	ORDER BY prv.[value] ASC

	OPEN partition_numbers

	FETCH NEXT FROM partition_numbers 
	INTO @partition_to_switch, @boundary_value, @rows

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		
		DECLARE @partition_switch_text VARCHAR(1000)
		SET @partition_switch_text = 'ALTER TABLE dbo.InvoicesPT_FG SWITCH PARTITION ' + CONVERT(VARCHAR(3), @partition_to_switch) + ' TO dbo.InvoicesPT_FG_Staging PARTITION ' + CONVERT(VARCHAR(3), @partition_to_switch) + ';' 

		SET @logmessage = 'Purging ' + CONVERT(VARCHAR, @rows) + ' rows for month beginning ' + CONVERT(VARCHAR(23), @boundary_value, 121)
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

		SET @logmessage = 'Running command: ' + @partition_switch_text
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

		EXEC(@partition_switch_text)


		FETCH NEXT FROM partition_numbers
		INTO @partition_to_switch, @boundary_value, @rows

	END

	CLOSE partition_numbers
	DEALLOCATE partition_numbers

	SET @logmessage = 'Running command: TRUNCATE TABLE dbo.InvoicesPT_FG_Staging'
	PRINT @logmessage
	INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)	

	TRUNCATE TABLE dbo.InvoicesPT_FG_Staging;

	SET @logmessage = 'Running command: DROP TABLE dbo.InvoicesPT_FG_Staging'
	PRINT @logmessage
	INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

	DROP TABLE dbo.InvoicesPT_FG_Staging

-- Merge ranges and drop filegroups/files

	DECLARE @filegroup_to_drop VARCHAR(30)
	DECLARE @file_to_drop VARCHAR(30)

	DECLARE boundaries CURSOR LOCAL
	FOR
	SELECT CONVERT(DATETIME, prv.[value]), ds2.[name], df.[name], p.[rows]
	FROM sys.partitions p
	INNER JOIN sys.indexes i
		ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
	INNER JOIN sys.partition_schemes ps
		ON i.data_space_id = ps.data_space_id
	INNER JOIN sys.destination_data_spaces dds
		ON ps.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
	INNER JOIN sys.data_spaces ds2
		ON dds.data_space_id = ds2.data_space_id
	INNER JOIN sys.database_files df
		ON ds2.data_space_id = df.data_space_id
	INNER JOIN sys.partition_functions pf
		ON ps.function_id = pf.function_id
	LEFT JOIN sys.partition_range_values prv
		ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
	WHERE OBJECT_NAME(p.[object_id]) = 'InvoicesPT_FG'
		AND p.index_id = 1
		AND prv.[value] < @PurgeDate
	ORDER BY prv.[value] ASC

	OPEN boundaries

	-- Re-use @boundary_value and @rows variables from prior loop
	FETCH NEXT FROM boundaries 
	INTO @boundary_value, @filegroup_to_drop, @file_to_drop, @rows

	WHILE @@FETCH_STATUS = 0  
	BEGIN

		DECLARE @merge_partition_text VARCHAR(2000)
		SET @merge_partition_text = 'ALTER PARTITION FUNCTION pf_Monthly_FG() MERGE RANGE (''' + CONVERT(VARCHAR(23), @boundary_value, 121) + ''');'

		DECLARE @drop_file_text VARCHAR(2000);
		SET @drop_file_text = 'ALTER DATABASE TestDatabase REMOVE FILE ' + @file_to_drop + ';'

		DECLARE @drop_filegroup_text VARCHAR(2000);
		SET @drop_filegroup_text = 'ALTER DATABASE TestDatabase REMOVE FILEGROUP ' + @filegroup_to_drop + ';'

		SET @logmessage = 'Running command: ' + @merge_partition_text
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		EXEC (@merge_partition_text)

	-- Checks rows have been switched
		DECLARE @rows_left BIGINT

		SELECT @rows_left = p.[rows]
		FROM sys.partitions p
		INNER JOIN sys.indexes i
			ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
		INNER JOIN sys.partition_schemes ps
			ON i.data_space_id = ps.data_space_id
		INNER JOIN sys.destination_data_spaces dds
			ON ps.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
		INNER JOIN sys.data_spaces ds2
			ON dds.data_space_id = ds2.data_space_id
		INNER JOIN sys.database_files df
			ON ds2.data_space_id = df.data_space_id
		INNER JOIN sys.partition_functions pf
			ON ps.function_id = pf.function_id
		LEFT JOIN sys.partition_range_values prv
			ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
		WHERE OBJECT_NAME(p.[object_id]) = 'InvoicesPT_FG'
			AND p.index_id = 1
			AND prv.[value] = @boundary_value

		IF @rows_left <> 0
		BEGIN
			SET @logmessage = 'Error - ' + CONVERT(VARCHAR, @rows_left) + ' rows still in partition. Execution cancelled.'
			PRINT @logmessage
			INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
			RETURN -1
		END

		SET @logmessage = 'Running command: ' + @drop_file_text
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		EXEC (@drop_file_text)

		SET @logmessage = 'Running command: ' + @drop_filegroup_text
		PRINT @logmessage
		INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
		EXEC (@drop_filegroup_text)
		

		FETCH NEXT FROM boundaries
		INTO @boundary_value, @filegroup_to_drop, @file_to_drop, @rows

	END

	CLOSE boundaries
	DEALLOCATE boundaries

	SET @logmessage = 'Finished procedure'
	PRINT @logmessage
	INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

END TRY
BEGIN CATCH
      IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

      DECLARE @errormsg NVARCHAR(2048) = ERROR_MESSAGE()
	  PRINT @errormsg
      SET @logmessage = 'Unexpected error occured - see subsequent message'
	  INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)
	  INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@errormsg)
      RETURN -1
END CATCH

END
