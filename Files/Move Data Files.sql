
/**************************************************************************************
*** Move Data Files
*** 
*** Move database data files. Requires taking DB offline.
***
*** Ver		Date      Author
*** 1.0		20/03/19	Alex Stuart
*** 
***************************************************************************************/

USE master
GO

-- Get 'name' of database files
SELECT database_id, file_id, type_desc, name, physical_name, state_desc, size, max_size, growth
FROM sys.master_files
WHERE database_id = DB_ID('databasename')

-- MODIFY FILE, passing parameters of the name of the database file and the *destination* filename
ALTER DATABASE databasename
MODIFY FILE (NAME = '', FILENAME = '')

-- Set DB offline and roll back any open transactions
ALTER DATABASE databasename
SET OFFLINE WITH ROLLBACK IMMEDIATE

-- Now move the file on the server

-- Bring database back online
ALTER DATABASE databasename
SET ONLINE
