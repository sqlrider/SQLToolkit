SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_AddPartition]
AS
BEGIN

SET NOCOUNT, XACT_ABORT ON

DECLARE @logmessage NVARCHAR(2048)
DECLARE @sql NVARCHAR(2048)

DECLARE @HighestBoundary DATETIME
DECLARE @HighestFilegroup VARCHAR(30)
DECLARE @HighestFilename VARCHAR(30)
DECLARE @HighestPhysicalName VARCHAR(250)
DECLARE @HighestFileNumber INT

DECLARE @NextBoundary DATETIME
DECLARE @NextFileNumber INT
DECLARE @NextFileGroup VARCHAR(30)
DECLARE @NextFilename VARCHAR(30)
DECLARE @NextPhysicalName VARCHAR(250)


SET @logmessage = 'Automated partition add process for dbo.Bill_Line started'
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

BEGIN TRY

SELECT TOP 1 @HighestBoundary = CONVERT(DATETIME, prv.value), @HighestFilegroup = ds2.[name], @HighestFilename = mf.[name], @HighestPhysicalName = mf.[physical_name]
FROM sys.partitions p
INNER JOIN sys.indexes i
	ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
INNER JOIN sys.partition_schemes ps
	ON i.data_space_id = ps.data_space_id
INNER JOIN sys.destination_data_spaces dds
	ON ps.data_space_id = dds.partition_scheme_id AND p.partition_number = dds.destination_id
INNER JOIN sys.data_spaces ds2
	ON dds.data_space_id = ds2.data_space_id
INNER JOIN sys.master_files mf	
	ON ds2.data_space_id = mf.data_space_id
INNER JOIN sys.partition_functions pf
	ON ps.function_id = pf.function_id
INNER JOIN sys.index_columns ic
	ON ic.[object_id] = p.[object_id] AND ic.partition_ordinal = 1 AND ic.index_id = 1
INNER JOIN sys.columns c
	ON ic.column_id = c.column_id AND p.[object_id] = c.[object_id]
LEFT JOIN sys.partition_range_values prv
	ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
WHERE OBJECT_NAME(p.[object_id]) = 'InvoicesPT_FG'
	AND p.index_id = 1
ORDER BY p.partition_number DESC


SET @logmessage = 'Current highest partition boundary is ' + CONVERT(VARCHAR(23), @HighestBoundary, 121) + ' on filegroup: ' + @HighestFilegroup + ', filename: ' + @HighestFilename + ', physical name: ' + @HighestPhysicalName
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

IF @HighestBoundary IS NULL
BEGIN
	SET @logmessage = 'Error in partition structure - highest numbered partition has no boundary value. Run usp_CheckPartitions to diagnose and resolve resolve. Procedure aborting'
	PRINT @logmessage
	RETURN -1
END

SET @NextBoundary = DATEADD(MONTH, 1, @HighestBoundary)

SELECT @HighestFileNumber = CAST(SUBSTRING(@HighestFilegroup, PATINDEX('%[0-9]%', @HighestFilegroup), LEN(@HighestFilegroup)) AS INT)

SET @NextFileNumber = @HighestFileNumber + 1

SET @NextFileGroup = REPLACE(@HighestFilegroup, @HighestFileNumber, @NextFileNumber)
SET @NextFilename = REPLACE(@HighestFilename, @HighestFileNumber, @NextFileNumber)
SET @NextPhysicalName = REPLACE(@HighestPhysicalName, @HighestFileNumber, @NextFileNumber)

SET @logmessage = 'Creating a new file. Filegroup: ' + @NextFileGroup + ', filename: ' + @NextFilename + ', physical name: ' + @NextPhysicalName
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

SET @sql = 'ALTER DATABASE TestDatabase ADD FILEGROUP ' + @NextFileGroup

SET @logmessage = 'Running command: ' + @sql
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

EXEC(@sql)

SET @sql = 'ALTER DATABASE TestDatabase ADD FILE (NAME = ' + @NextFilename + ', FILENAME = ''' + @NextPhysicalName + ''', SIZE = 10MB, MAXSIZE = 50MB, FILEGROWTH = 5MB) TO FILEGROUP ' + @NextFileGroup + ';'

SET @logmessage = 'Running command: ' + @sql
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

EXEC(@sql)

SET @sql = 'ALTER PARTITION SCHEME ps_Monthly_FG NEXT USED ' + @NextFileGroup

SET @logmessage = 'Running command: ' + @sql
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

EXEC (@sql)

SET @sql = 'ALTER PARTITION FUNCTION pf_Monthly_FG() SPLIT RANGE (''' + CONVERT(VARCHAR(23), @NextBoundary, 121) + ''');'

SET @logmessage = 'Running command: ' + @sql
PRINT @logmessage
INSERT INTO dbo.DBA_Partition_Management_Log (LogMessage) VALUES (@logmessage)

EXEC (@sql)

SET @logmessage = 'Procedure completed.'
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



GO
