/*******************************************************************************************************************
*** Copy-only Backup
*** 
*** Perform a copy-only backup.
***
*** Ver		Date		Author
*** 1.0		29/08/18	Alex Stuart
*** 
********************************************************************************************************************/

USE master
GO

BACKUP DATABASE [databasename]
TO DISK = N'\\sharename\foldername\filename.bak'
WITH COPY_ONLY,										-- Doesn't affect backup sequence
-- COMPRESSION,										-- Compression
NOFORMAT,											-- Preserves existing media header/backupset on media volume
NOINIT,												-- Appends to most recent backupset. INIT overwrites backupset
NAME = N'DBName-Full Database Backup',
SKIP,												-- Disables checking of backupset expiration
NOREWIND,											-- Only used for tape drives - no rewind
NOUNLOAD,											-- Only used for tape drives - no unload
STATS = 10											-- Percentage chunks of completion to show in Messages tab
GO
