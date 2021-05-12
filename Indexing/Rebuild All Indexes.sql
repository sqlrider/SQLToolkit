
/***************************************************************
*** Rebuild all indexes on a database
***
*** Rebuilds all indexes on a specified database.
***
*** Ver	Date		By				Change
*** 1.0	08/10/2018	Alex Stuart
***
****************************************************************/
CREATE PROCEDURE dbo.RebuildAllIndexes @dbname VARCHAR(128)
AS
BEGIN

DECLARE @tablename VARCHAR(255)
DECLARE @sql NVARCHAR(500)

DECLARE tablescursor CURSOR FOR
	SELECT '[' + OBJECT_SCHEMA_NAME([object_id])+'].['+name+']' AS TableName
	FROM sys.tables
OPEN TableCursor

FETCH NEXT FROM TableCursor INTO @TableName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = 'USE [' + @dbname + '];
	
				ALTER INDEX ALL
				ON ' + @TableName + ' REBUILD WITH (FILLFACTOR = 100)'

	EXEC (@sql)

	FETCH NEXT FROM TableCursor INTO @TableName
END
CLOSE TableCursor
DEALLOCATE TableCursor

END
