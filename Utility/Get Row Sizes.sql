/******************************************************************************************************************
*** Get Table Row Sizes
***
*** Queries for getting the maximum (rows*sizes) or average (sample DATALENGTH) column size in a table.
*** The simple summation is accurate only for fixed-length datatypes.
*** Uncomment and use the WHERE filter to sample a specific subset of rows if required for better representation.
***
*** Ver		Date		Author				Change
*** 1.0		01/10/18	Alex Stuart			Initial version.
***
*******************************************************************************************************************/

-- Simple summation of rows * size
SELECT SUM(max_length) AS 'bytes'
FROM sys.columns
WHERE object_id = OBJECT_ID('schema.tablename')


-- Sampled calculation of actual row size for variable-length columns.
DECLARE @tablename VARCHAR(128);   
DECLARE @SQL VARCHAR(MAX);

SET @tablename = 'schema.tablename'  
SET @SQL = 'SELECT TOP 100 (0'  

SELECT @SQL = @SQL + ' + ISNULL(DATALENGTH(' + name + '), 1)'  
FROM sys.columns
WHERE [object_id] = OBJECT_ID(@tablename)  

SET @SQL = @SQL + ') as RowSize from ' + @tablename -- + 'WHERE ......'

EXEC(@SQL)  
