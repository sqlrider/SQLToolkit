/**************************************************************************************
*** Restore Backup Encryption Certificate
*** 
*** Restore a backup encryption certificate to another server for restoring an
*** encrypted backup.
***
*** Ver		Date		Author
*** 1.0		08/03/17	Alex Stuart
*** 
***************************************************************************************/




--- On source server
-- 1.1
-- Identify certificate used by backup process
SELECT d.name, b.key_algorithm, b.encryptor_type, b.encryptor_thumbprint, c.name, c.pvt_key_encryption_type_desc, c.[start_date], c.[expiry_date]
FROM [master].sys.databases d
CROSS APPLY (SELECT TOP 1 bs.key_algorithm, bs.encryptor_type, bs.encryptor_thumbprint
			 FROM msdb.dbo.backupset bs
			 WHERE bs.database_name = d.name
			 ORDER BY bs.backup_set_id DESC) b
LEFT OUTER JOIN [master].sys.certificates c
	ON b.encryptor_thumbprint = c.thumbprint
WHERE d.name = 'database_name'


-- 1.2
-- Backup certificate to disk using PRIVATE KEY
BACKUP CERTIFICATE servername_BackupCert
TO FILE = 'D:\AS\servername_Backup_Cert.cer'
WITH PRIVATE KEY
(
    FILE = 'D:\AS\servername_Backup_Key.key',
	ENCRYPTION BY PASSWORD = 'password'
);

-- 1.3
-- Copy certificate and private key to destination server


--- On destination server
-- 2.1
-- Create master key if one doesn't already exist
USE master
GO;

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'password'

-- 2.2
-- Create new certificate from the backup and private key
CREATE CERTIFICATE servername_BackupCert
FROM FILE = 'D:\AS\servername_Backup_Cert.cer'
WITH PRIVATE KEY
(
    FILE = 'D:\AS\servername_Backup_Key.key',
	DECRYPTION BY PASSWORD = 'password'
);
