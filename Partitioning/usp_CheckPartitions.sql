SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_CheckPartitions] @table SYSNAME
AS
BEGIN

SELECT OBJECT_NAME(p.[object_id]) AS 'Table', i.[name] AS 'Index', pf.[name] AS 'PFunction', ps.[name] AS 'PScheme', ds2.[name] AS 'DestFG',  
		CASE pf.boundary_value_on_right 
			WHEN 0 THEN 'RANGE LEFT'
			ELSE 'RANGE RIGHT' END AS 'BoundaryType',
		p.partition_number AS 'PartitionNumber', p.[rows], prv.value AS 'Boundary',
		c.name + ' >= ' + CONVERT(VARCHAR(23), ISNULL(prv.value, 'Min/Max'), 121) + ' and < ' + CONVERT(VARCHAR(23), ISNULL(LEAD(prv.value) OVER(PARTITION BY p.[object_id] ORDER BY p.[object_id], p.partition_number), 'Min/Max'), 121) AS 'Range'
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
INNER JOIN sys.index_columns ic
	ON ic.[object_id] = p.[object_id] AND ic.partition_ordinal = 1 AND ic.index_id = 1
INNER JOIN sys.columns c
	ON ic.column_id = c.column_id AND p.[object_id] = c.[object_id]
LEFT JOIN sys.partition_range_values prv
	ON pf.function_id = prv.function_id AND p.partition_number = (CASE pf.boundary_value_on_right WHEN 0 THEN prv.boundary_id ELSE (prv.boundary_id + 1) END)
WHERE OBJECT_NAME(p.[object_id]) = @table
	AND p.index_id = 1

END
GO
