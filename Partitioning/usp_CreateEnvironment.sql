SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CreateEnvironment]
AS
BEGIN

	-- Drop existing objects

	IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'InvoicesPT_FG')
		DROP TABLE dbo.InvoicesPT_FG;

	IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'InvoicesPT_FG_Staging')
		DROP TABLE dbo.InvoicesPT_FG_Staging;

	IF EXISTS (SELECT 1 FROM sys.partition_schemes WHERE [name] = 'ps_Monthly_FG')
		DROP PARTITION SCHEME ps_Monthly_FG;

	IF EXISTS (SELECT 1 FROM sys.partition_functions WHERE [name] = 'pf_Monthly_FG')
		DROP PARTITION FUNCTION pf_Monthly_FG;

	IF EXISTS (SELECT 1 FROM sys.tables WHERE [name] = 'Nums')
		DROP TABLE dbo.Nums

	CREATE TABLE dbo.Nums (a INT)

	INSERT INTO dbo.Nums (a) VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20)
	
	DECLARE fgdrop CURSOR LOCAL
	FOR
	SELECT a FROM dbo.Nums
	WHERE a > 0

	DECLARE @a INT;
	DECLARE @sqltext NVARCHAR(4000);
	DECLARE @x NVARCHAR(2)
	DECLARE @messagetext VARCHAR(50)

	OPEN fgdrop
  
	FETCH NEXT FROM fgdrop   
	INTO @a
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @x = CAST(@a AS NVARCHAR(2))

		SET @sqltext = 
			'ALTER DATABASE TestDatabase
			 REMOVE FILE FG' + @x + '_file;

			ALTER DATABASE TestDatabase
			REMOVE FILEGROUP FG' + @x + ';'

		EXEC sp_executesql @sqltext
		
		SET @messagetext = 'Removed file FG' + @x + '_file and FG' + @x + ' filegroup'
		PRINT @messagetext

		FETCH NEXT FROM fgdrop
		INTO @a
	END

	CLOSE fgdrop
	DEALLOCATE fgdrop

	-- Create filegroups and files
	DECLARE fgcreate CURSOR LOCAL
	FOR
	SELECT a FROM dbo.Nums
	WHERE a > 0
	AND a < 20

	OPEN fgcreate 
  
	FETCH NEXT FROM fgcreate   
	INTO @a
  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SET @x = CAST(@a AS NVARCHAR(2))

		SET @sqltext = 
			'ALTER DATABASE TestDatabase
			ADD FILEGROUP FG' + @x + ';

			ALTER DATABASE TestDatabase
			ADD FILE 
			(
				NAME = FG' + @x + '_file,
				FILENAME = ''C:\SQL\DATA\FG' + @x + '.ndf'',
				SIZE = 10MB,
				MAXSIZE = 50MB,
				FILEGROWTH = 5MB
			)
			TO FILEGROUP FG' + @x +';'

		EXEC sp_executesql @sqltext

		SET @messagetext = 'Added FG' + @x + ' filegroup and file FG' + @x + '_file'
		PRINT @messagetext

		FETCH NEXT FROM fgcreate
		INTO @a
	END

	CLOSE fgcreate
	DEALLOCATE fgcreate

	-- Create PF
	CREATE PARTITION FUNCTION pf_Monthly_FG (DATETIME)
	AS
	RANGE RIGHT FOR VALUES
	('2016-01-01 00:00:00.000',
	'2016-02-01 00:00:00.000',
	'2016-03-01 00:00:00.000',
	'2016-04-01 00:00:00.000',
	'2016-05-01 00:00:00.000',
	'2016-06-01 00:00:00.000',
	'2016-07-01 00:00:00.000',
	'2016-08-01 00:00:00.000',
	'2016-09-01 00:00:00.000',
	'2016-10-01 00:00:00.000',
	'2016-11-01 00:00:00.000',
	'2016-12-01 00:00:00.000',
	'2017-01-01 00:00:00.000',
	'2017-02-01 00:00:00.000',
	'2017-03-01 00:00:00.000',
	'2017-04-01 00:00:00.000',
	'2017-05-01 00:00:00.000',
	'2017-06-01 00:00:00.000')


	-- Create File-based Partition Scheme
	CREATE PARTITION SCHEME ps_Monthly_FG
	AS
	PARTITION pf_Monthly_FG TO ([FG1],[FG2],[FG3],[FG4],
							[FG5],[FG6],[FG7],[FG8],
							[FG9],[FG10],[FG11],[FG12],
							[FG13],[FG14],[FG15],[FG16],
							[FG17],[FG18],[FG19])

	-- Create base table
	EXEC usp_CreateBaseTableFG

	-- Check partitions query
	EXEC usp_CheckPartitions 'InvoicesPT_FG'

END

GO
