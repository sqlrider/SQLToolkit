/********************************************************************************************************
*** Backup Info
***
***	Script to Rretrieve backup and backup job information for either native or Redgate backups.
*** Final part of code assumes Ola Hallengren backup job naming convention - 'NativeBackup - type', etc.
***
*** Ver		Date		Author			Comment
*** 1.0		12/06/19	Alex Stuart
***
*********************************************************************************************************/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @version INT;
SET @version = CAST(REPLACE(SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)),1,2), '.', '') AS INT);

IF @version <= 11					-- <= 2012, no encrypted backups
BEGIN

	IF EXISTS	(
					SELECT 1
					FROM msdb.dbo.backupmediafamily bmf
					INNER JOIN msdb.dbo.backupset bs
						ON bmf.media_set_id = bs.media_set_id
					WHERE bs.backup_start_date < DATEADD(DAY, -30, GETDATE())
					AND bmf.logical_device_name LIKE 'Red Gate%'
				)
	BEGIN
		DECLARE @REDGATE_BACKUP_INFO TABLE ( 
		[REDGATE_ID] INT 
		,[BACKUP_START] DATETIME 
		,[BACKUP_END] DATETIME 
		,[BACKUP_TYPE] VARCHAR(1) 
		,[DATABASE_NAME] VARCHAR(100) 
		,[ENCRYPTION] TINYINT 
		,[COMPRESSION_RATIO] REAL 
		,[COMPRESSION_LEVEL] TINYINT 
		,[SIZE] BIGINT 
		,[COMPRESSED_SIZE] BIGINT 
		,[SPEED] REAL 
		,[FILE_COUNT] TINYINT 
		,[USER_NAME] VARCHAR(30) 
		,[LOGFILENAME] VARCHAR(200) 
		,[BACKUP_LOCATION] VARCHAR(200) 
		,[COPY_LOCATION] VARCHAR(200) 
		)


		DECLARE @SQLSTATEMENT VARCHAR(1000) 
		SET @SQLSTATEMENT = (' 
		SELECT  
		A.ID 
		,A.BACKUP_START 
		,A.BACKUP_END 
		,A.BACKUP_TYPE 
		,A.DBNAME 
		,A.ENCRYPTION 
		,A.COMPRESSION_RATIO 
		,A.COMPRESSION_LEVEL 
		,A.SIZE / 1024 / 1024
		,A.COMPRESSED_SIZE / 1024 / 1024
		,A.SPEED 
		,A.FILE_COUNT 
		,A.USER_NAME 
		,A.LOGFILENAME 
		,CASE WHEN B.FILE_TYPE =''P'' THEN B.NAME END AS BACKUP_LOCATION 
		,CASE WHEN C.FILE_TYPE =''C'' THEN C.NAME END AS COPY_LOCATION 
		FROM BACKUPHISTORY A 
		JOIN BACKUPFILES B 
			ON A.ID = B.BACKUP_ID 
		JOIN BACKUPFILES C 
			ON A.ID = C.BACKUP_ID 
			AND B.SIZE = C.SIZE 
			AND B.COMPRESSED_SIZE = C.COMPRESSED_SIZE 
		WHERE B.FILE_TYPE = ''P''
		AND BACKUP_START < DATEADD(DAY, -30, GETDATE())
		ORDER BY A.ID DESC  
		')

		INSERT INTO @REDGATE_BACKUP_INFO 
		EXECUTE MASTER..SQBDATA @SQLSTATEMENT

		SELECT DISTINCT
			SERVERPROPERTY('MachineName') AS [MachineName],
			CASE RIGHT(SUBSTRING(@@VERSION, CHARINDEX('Windows NT', @@VERSION), 14), 3)
   				WHEN '5.0' THEN 'Windows 2000'
				WHEN '5.2' THEN 'Windows Server 2003'
				WHEN '6.0' THEN 'Windows Server 2008'
				WHEN '6.1' THEN 'Windows Server 2008 R2'
				WHEN '6.2' THEN 'Windows Server 2012'
				WHEN '6.3' THEN 'Windows Server 2012 R2'
				WHEN '10.0' THEN 'Windows Server 2016'
			END AS 'WindowsVersion',
			CASE SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)),0,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50))) + 2)
				WHEN '8.0' THEN '2000'
				WHEN '9.0' THEN '2005'
				WHEN '10.0' THEN '2008'
				WHEN '10.5' THEN '2008 R2'
				WHEN '11.0' THEN '2012'
				WHEN '12.0' THEN '2014'
				WHEN '13.0' THEN '2016'
			END AS 'SQL Version',
			SERVERPROPERTY('ProductLevel') AS 'ServicePack',
			SERVERPROPERTY('IsClustered') AS 'IsClustered',
			SERVERPROPERTY('ServerName') AS [InstanceName],
			DB_NAME(d.database_id) AS 'database_name',
			DbSize.[Size(MB)],
			'RG' AS 'is_compressed',
			'N/A' AS 'is_encrypted',
			'Full' AS 'Full', NULL AS 'FullSchedule(Days)', NULL AS 'FullTime', FullBackups.Size AS 'FullSize(MB)', FullBackups.Compressed_Size AS 'FullCompressedSize(MB)',
			'Diff' AS 'Diff', NULL AS 'DiffSchedule(Days)', NULL AS 'DiffTime', DiffBackups.Size AS 'DiffSize(MB)', DiffBackups.Compressed_Size AS 'DiffCompressedSize(MB)',
			'Log' AS 'Log', NULL AS 'LogSchedule(Minutes)', NULL AS 'LogTime', LogBackups.Size AS 'LogSize(MB)', LogBackups.Compressed_Size AS 'LogCompressedSize(MB)'
		FROM sys.databases d
		CROSS APPLY (SELECT database_id, SUM((CAST(size AS BIGINT) * 8) / 1024) AS 'Size(MB)'
							FROM sys.master_files
							WHERE database_id = d.database_id
							GROUP BY database_id) DbSize
		OUTER APPLY (SELECT TOP 1 rbi.SIZE, rbi.COMPRESSED_SIZE
					 FROM @REDGATE_BACKUP_INFO rbi
					 WHERE rbi.DATABASE_NAME = DB_NAME(d.database_id)
					 AND rbi.BACKUP_TYPE = 'D'
					 ORDER BY BACKUP_START DESC) FullBackups
		OUTER APPLY (SELECT TOP 1 rbi.SIZE, rbi.COMPRESSED_SIZE
					 FROM @REDGATE_BACKUP_INFO rbi
					 WHERE rbi.DATABASE_NAME = DB_NAME(d.database_id)
					 AND rbi.BACKUP_TYPE = 'I'
					 ORDER BY BACKUP_START DESC) DiffBackups
		OUTER APPLY (SELECT TOP 1 rbi.SIZE, rbi.COMPRESSED_SIZE
					 FROM @REDGATE_BACKUP_INFO rbi
					 WHERE rbi.DATABASE_NAME = DB_NAME(d.database_id)
					 AND rbi.BACKUP_TYPE = 'L'
					 ORDER BY BACKUP_START DESC) LogBackups
		WHERE d.database_id <> 2
	END
	ELSE
	BEGIN
		SELECT DISTINCT
		SERVERPROPERTY('MachineName') AS [MachineName],
		CASE RIGHT(SUBSTRING(@@VERSION, CHARINDEX('Windows NT', @@VERSION), 14), 3)
   			WHEN '5.0' THEN 'Windows 2000'
			WHEN '5.2' THEN 'Windows Server 2003'
			WHEN '6.0' THEN 'Windows Server 2008'
			WHEN '6.1' THEN 'Windows Server 2008 R2'
			WHEN '6.2' THEN 'Windows Server 2012'
			WHEN '6.3' THEN 'Windows Server 2012 R2'
			WHEN '10.0' THEN 'Windows Server 2016/2019'
		END AS 'WindowsVersion',
		CASE SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)),0,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50))) + 2)
			WHEN '8.0' THEN '2000'
			WHEN '9.0' THEN '2005'
			WHEN '10.0' THEN '2008'
			WHEN '10.5' THEN '2008 R2'
			WHEN '11.0' THEN '2012'
			WHEN '12.0' THEN '2014'
			WHEN '13.0' THEN '2016'
			WHEN '14.0' THEN '2017'
			WHEN '15.0' THEN '2019'
		END AS 'SQL Version',
		SERVERPROPERTY('ProductLevel') AS 'ServicePack',
		SERVERPROPERTY('IsClustered') AS 'IsClustered',
		SERVERPROPERTY('ServerName') AS [InstanceName],
		DB_NAME(d.database_id) AS 'database_name',
		DbSize.[Size(MB)],
		'N/A' AS 'is_compressed',
		'N/A' AS 'is_encrypted',
		'Full' AS 'Full', FullSched.[Schedule(Days)] AS 'FullSchedule(Days)', FullSched.[Time] AS 'FullTime', CONVERT(BIGINT, FullBackups.[Size(MB)]) AS 'FullSize(MB)', 'N/A' AS 'FullCompressedSize(MB)',
		'Diff' AS 'Diff', DiffSched.[Schedule(Days)] AS 'DiffSchedule(Days)', DiffSched.[Time] AS 'DiffTime', CONVERT(BIGINT, DiffBackups.[Size(MB)]) AS 'DiffSize(MB)', 'N/A' AS 'DiffCompressedSize(MB)',
		'Log' AS 'Log', LogSched.[Schedule(Minutes)] AS 'LogSchedule(Minutes)', LogSched.[Time] AS 'LogTime', CONVERT(BIGINT, LogBackups.[Size(MB)]) AS 'LogSize(MB)', 'N/A' AS 'LogCompressedSize(MB)'
	FROM sys.databases d
	LEFT OUTER JOIN msdb.dbo.backupset bs 
		ON DB_NAME(d.database_id) = bs.database_name AND bs.backup_start_date >= DATEADD(DAY, -30, GETDATE())
	LEFT OUTER JOIN msdb.dbo.backupmediaset bms
		ON bs.media_set_id = bms.media_set_id
	LEFT OUTER JOIN msdb.dbo.backupmediafamily bmf
		ON bs.media_set_id = bmf.media_set_id
	CROSS APPLY (SELECT database_id, SUM((CAST(size AS BIGINT) * 8) / 1024) AS 'Size(MB)'
					FROM sys.master_files
					WHERE database_id = d.database_id
					GROUP BY database_id) DbSize
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'D'
					AND is_copy_only = 0
					ORDER BY backup_set_id DESC) FullBackups
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'I'
					ORDER BY backup_set_id DESC) DiffBackups
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'L'
					ORDER BY backup_set_id DESC) LogBackups
	OUTER APPLY (SELECT j.name, DATEDIFF(DAY,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Days)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
					FROM msdb.dbo.sysjobs j
					CROSS APPLY (SELECT TOP 1 *
								FROM msdb.dbo.sysjobactivity ja
								WHERE ja.job_id = j.job_id
								ORDER BY ja.start_execution_date DESC) ja
					WHERE (j.name = 'NativeBackup - FULL' OR j.name = 'RedgateBackup - FULL')
					AND j.[enabled] = '1') FullSched
	OUTER APPLY (SELECT j.name, DATEDIFF(DAY,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Days)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
					FROM msdb.dbo.sysjobs j
					CROSS APPLY (SELECT TOP 1 *
								FROM msdb.dbo.sysjobactivity ja
								WHERE ja.job_id = j.job_id
								ORDER BY ja.start_execution_date DESC) ja
					WHERE (j.name = 'NativeBackup - DIFF' OR j.name = 'RedgateBackup - DIFF')
					AND j.[enabled] = '1') DiffSched
	OUTER APPLY (SELECT j.name, DATEDIFF(MINUTE,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Minutes)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
					FROM msdb.dbo.sysjobs j
					CROSS APPLY (SELECT TOP 1 *
								FROM msdb.dbo.sysjobactivity ja
								WHERE ja.job_id = j.job_id
								ORDER BY ja.start_execution_date DESC) ja
					WHERE (j.name = 'NativeBackup - LOG' OR j.name = 'RedgateBackup - LOG')
					AND j.[enabled] = '1') LogSched
	WHERE d.database_id NOT IN (2,3) 
	AND ( (bs.backup_set_id = FullBackups.backup_set_id
				OR bs.backup_set_id = DiffBackups.backup_set_id
				OR bs.backup_set_id = LogBackups.backup_set_id)
			OR bs.backup_start_date IS NULL)
	END
END
ELSE -- IF @version >= 12					=> 2014, encrypted backups
BEGIN
	SELECT DISTINCT 
		SERVERPROPERTY('MachineName') AS [MachineName],
		wininfo.WindowsVersion,
		CASE SUBSTRING(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50)),0,CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(50))) + 2)
			WHEN '8.0' THEN '2000'
			WHEN '9.0' THEN '2005'
			WHEN '10.0' THEN '2008'
			WHEN '10.5' THEN '2008 R2'
			WHEN '11.0' THEN '2012'
			WHEN '12.0' THEN '2014'
			WHEN '13.0' THEN '2016'
		END AS 'SQL Version',
		SERVERPROPERTY('ProductLevel') AS 'ServicePack',
		SERVERPROPERTY('IsClustered') AS 'IsClustered',
		SERVERPROPERTY('ServerName') AS [InstanceName],
		DB_NAME(d.[database_id]) AS 'database_name',
		DbSize.[Size(MB)],
		ISNULL(bms.is_compressed, 0) AS 'is_compressed',
		ISNULL(bms.is_encrypted, 0) AS 'is_encrypted',
		'Full' AS 'Full', FullSched.[Schedule(Days)] AS 'FullSchedule(Days)', FullSched.[Time] AS 'FullTime', CONVERT(BIGINT, FullBackups.[Size(MB)]) AS 'FullSize(MB)', CONVERT(BIGINT, FullBackups.[Compressed_Size(MB)]) AS 'FullCompressedSize(MB)',
		'Diff' AS 'Diff', DiffSched.[Schedule(Days)] AS 'DiffSchedule(Days)', DiffSched.[Time] AS 'DiffTime', CONVERT(BIGINT, DiffBackups.[Size(MB)]) AS 'DiffSize(MB)', CONVERT(BIGINT, DiffBackups.[Compressed_Size(MB)]) AS 'DiffCompressedSize(MB)',
		'Log' AS 'Log', LogSched.[Schedule(Minutes)] AS 'LogSchedule(Minutes)', LogSched.[Time] AS 'LogTime', CONVERT(BIGINT, LogBackups.[Size(MB)]) AS 'LogSize(MB)', CONVERT(BIGINT, LogBackups.[Compressed_Size(MB)]) AS 'LogCompressedSize(MB)'
	FROM sys.databases d
	LEFT OUTER JOIN msdb.dbo.backupset bs 
		ON DB_NAME(d.database_id) = bs.database_name AND bs.backup_start_date >= DATEADD(DAY, -30, GETDATE())
	LEFT OUTER JOIN msdb.dbo.backupmediaset bms
		ON bs.media_set_id = bms.media_set_id
	LEFT OUTER JOIN msdb.dbo.backupmediafamily bmf
		ON bs.media_set_id = bmf.media_set_id
	CROSS APPLY (SELECT CASE CAST(windows_release AS VARCHAR(4))
					WHEN '5.0' THEN 'Windows 2000'
					WHEN '5.2' THEN 'Windows Server 2003'
					WHEN '6.0' THEN 'Windows Server 2008'
					WHEN '6.1' THEN 'Windows Server 2008 R2'
					WHEN '6.2' THEN 'Windows Server 2012'
					WHEN '6.3' THEN 'Windows Server 2012 R2'
					WHEN '10.0' THEN 'Windows Server 2016'
				END AS 'WindowsVersion'
				FROM sys.dm_os_windows_info) wininfo
	CROSS APPLY (SELECT database_id, SUM((CAST(size AS BIGINT) * 8) / 1024) AS 'Size(MB)'
					FROM sys.master_files
					WHERE database_id = d.database_id
					GROUP BY database_id) DbSize
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'D'
					AND is_copy_only = 0
					ORDER BY backup_set_id DESC) FullBackups
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'I'
					ORDER BY backup_set_id DESC) DiffBackups
	OUTER APPLY (SELECT TOP 1 backup_set_id, database_name, backup_start_date, backup_size / 1024 / 1024 AS 'Size(MB)', compressed_backup_size / 1024 / 1024 AS 'Compressed_Size(MB)'
					FROM msdb.dbo.backupset 
					WHERE database_name = bs.database_name
					AND [type] = 'L'
					ORDER BY backup_set_id DESC) LogBackups
	OUTER APPLY (SELECT j.name, DATEDIFF(DAY,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Days)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
				 FROM msdb.dbo.sysjobs j
				 CROSS APPLY (SELECT TOP 1 *
							  FROM msdb.dbo.sysjobactivity ja
							  WHERE ja.job_id = j.job_id
							  ORDER BY ja.start_execution_date DESC) ja
				 WHERE (j.name = 'NativeBackup - FULL' OR j.name = 'RedgateBackup - FULL')
				 AND j.[enabled] = '1') FullSched
	OUTER APPLY (SELECT j.name, DATEDIFF(DAY,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Days)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
					FROM msdb.dbo.sysjobs j
					CROSS APPLY (SELECT TOP 1 *
								FROM msdb.dbo.sysjobactivity ja
								WHERE ja.job_id = j.job_id
								ORDER BY ja.start_execution_date DESC) ja
					WHERE (j.name = 'NativeBackup - DIFF' OR j.name = 'RedgateBackup - DIFF')
					AND j.[enabled] = '1') DiffSched
	OUTER APPLY (SELECT j.name, DATEDIFF(MINUTE,ja.start_execution_date, ja.next_scheduled_run_date) AS 'Schedule(Minutes)', CONVERT(VARCHAR(23),ja.next_scheduled_run_date, 8) AS 'Time'
					FROM msdb.dbo.sysjobs j
					CROSS APPLY (SELECT TOP 1 *
								FROM msdb.dbo.sysjobactivity ja
								WHERE ja.job_id = j.job_id
								ORDER BY ja.start_execution_date DESC) ja
					WHERE (j.name = 'NativeBackup - LOG' OR j.name = 'RedgateBackup - LOG')
					AND j.[enabled] = '1') LogSched
	WHERE d.database_id NOT IN (2,3) 
		AND ( (bs.backup_set_id = FullBackups.backup_set_id
					OR bs.backup_set_id = DiffBackups.backup_set_id
					OR bs.backup_set_id = LogBackups.backup_set_id)
				OR bs.backup_start_date IS NULL)
END
