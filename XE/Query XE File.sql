/*******************************************************************************************************************
*** Query XE File
*** 
*** Skeleton query for interrogating an XE file
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/

USE master
GO

SELECT [timestamp], sql_text, duration / 1000 AS 'duration(ms)', logical_reads, physical_reads
FROM
(
	SELECT evt.[eventdata].value('(/event/@timestamp)[1]', 'datetime2') AS [timestamp],
	evt.[eventdata].value('(/event/action[@name="username"]/value)[1]', 'VARCHAR(20)') AS username,
	evt.[eventdata].value('(/event/action[@name="sql_text"]/value)[1]', 'VARCHAR(MAX)') AS sql_text,
	evt.[eventdata].value('(/event/data[@name="duration"]/value)[1]', 'int') AS duration,
	evt.[eventdata].value('(/event/data[@name="logical_reads"]/value)[1]', 'int') AS logical_reads,
	evt.[eventdata].value('(/event/data[@name="physical_reads"]/value)[1]', 'int') AS physical_reads
	FROM 
		(
			SELECT [object_name], CAST(event_data AS XML) AS 'eventdata'
			FROM sys.fn_xe_file_target_read_file('D:\AS\filename*.xel', NULL, null, null) AS event_data
		) evt
) xe
WHERE xe.username = 'domain\user'
AND sql_text NOT LIKE 'filter text'
ORDER BY xe.[timestamp] ASC
