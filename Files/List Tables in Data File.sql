/*******************************************************************************************************************
*** List Tables/Indexes in Data File
*** 
*** List tables/indexes in a given data file.
***
*** Ver		Date		Author
*** 1.0		23/01/19	Alex Stuart
*** 
********************************************************************************************************************/

-- Identify file in question and note data_space_id
SELECT database_id, DB_NAME(database_id) AS 'database_name', type_desc, name, physical_name, data_space_id
FROM sys.master_files
WHERE physical_name LIKE '%filename%'

-- data_space_id = 4

-- Use DB in question 
USE [databasename]
GO

-- List objects belonging to the data space - supply data_space_id from previous query
SELECT s.[name] AS 'schema', ao.name, ao.[type], i.type_desc AS 'table_type'
FROM sys.indexes i
INNER JOIN sys.filegroups f
	ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects ao
	ON i.[object_id] = ao.[object_id]
INNER JOIN sys.schemas s
	ON ao.[schema_id] = s.[schema_id]
WHERE i.data_space_id = 4


