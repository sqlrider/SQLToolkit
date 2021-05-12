/*******************************************************************************************************************
*** Buffer Cache Page Usage
***
*** Identifies buffer cache usage per-database, and of which is free space due to fillfactor, large row size etc
***
*** Ver		Date		Author
*** 1.0		17/09/18	Alex Stuart
***
********************************************************************************************************************/

USE master
GO

SELECT
    (CASE WHEN ([database_id] = 32767)
        THEN N'Resource Database'
        ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
    COUNT (*) * 8 / 1024 AS [MBUsed],
    SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
FROM sys.dm_os_buffer_descriptors
GROUP BY [database_id];
GO
