/*******************************************************************************************************************
*** DBs with AUTOSHRINK enabled
*** 
*** Lists any databases with AUTOSHRINK enabled and file(s) with a maximum size specified
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/


USE master
GO

SELECT d.name, d.database_id, d.is_auto_shrink_on, mf.name, mf.physical_name, mf.state_desc, mf.size, mf.max_size, CAST(((CAST(mf.size AS NUMERIC)/CAST(mf.max_size AS NUMERIC)) * 100) AS NUMERIC) AS 'PercentFull'
FROM sys.databases d
INNER JOIN sys.master_files mf
	ON d.database_id = mf.database_id
WHERE is_auto_shrink_on = 1
AND max_size <> '-1'
AND mf.type_desc = 'ROWS'
ORDER BY d.name ASC
