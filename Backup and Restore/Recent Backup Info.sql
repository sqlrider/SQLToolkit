/****************************************************************************************************
*** Recent Backup Information
*** 
*** Lists most recent backup information for all databases that have been backed up within 30 days.
***
*** Ver		Date		Author
*** 1.0		21/03/19	Alex Stuart
*** 
*****************************************************************************************************/
USE msdb
GO


SELECT DISTINCT bs.server_name,
bs.database_name,
DbSize.[Size(MB)],
bms.is_compressed,
bms.is_encrypted,
FullBackups.[Type], CONVERT(INT, FullBackups.[Size(MB)]) AS 'Size(MB)', CONVERT(INT,FullBackups.[Compressed_Size(MB)]) AS 'CompressedSize(MB)',
DiffBackups.[Type], CONVERT(INT, DiffBackups.[Size(MB)]) AS 'Size(MB)', CONVERT(INT,DiffBackups.[Compressed_Size(MB)]) AS 'CompressedSize(MB)',
LogBackups.[Type], CONVERT(INT, LogBackups.[Size(MB)]) AS 'Size(MB)', CONVERT(INT,LogBackups.[Compressed_Size(MB)]) AS 'CompressedSize(MB)'
FROM dbo.backupset bs 
INNER JOIN dbo.backupmediaset bms
	ON bs.media_set_id = bms.media_set_id
INNER JOIN dbo.backupmediafamily bmf
	ON bs.media_set_id = bmf.media_set_id
CROSS APPLY (SELECT database_id, SUM((size * 8) / 1024) AS 'Size(MB)'
			 FROM sys.master_files
			 WHERE database_id = DB_ID(bs.database_name)
			 GROUP BY database_id) DbSize
OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, 'Full' AS 'Type', backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
			 FROM dbo.backupset 
			 WHERE database_name = bs.database_name
			 AND [type] = 'D'
			 AND is_copy_only = 0
			 ORDER BY backup_set_id DESC) FullBackups
OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, 'Diff' AS 'Type', backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
			 FROM dbo.backupset 
			 WHERE database_name = bs.database_name
			 AND [type] = 'I'
			 ORDER BY backup_set_id DESC) DiffBackups
OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, 'Log' AS 'Type', backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
			 FROM dbo.backupset 
			 WHERE database_name = bs.database_name
			 AND [type] = 'L'
			 ORDER BY backup_set_id DESC) LogBackups
WHERE bs.backup_start_date >= DATEADD(DAY, -30, GETDATE())
AND (bs.backup_set_id = FullBackups.backup_set_id
	OR bs.backup_set_id = DiffBackups.backup_set_id
	OR bs.backup_set_id = LogBackups.backup_set_id)
ORDER BY bs.database_name ASC
