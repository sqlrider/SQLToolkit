/***********************************************************************************************************************************
*** Create And Backup Keys And Certificates
***
*** Backups up SMK, creates and backs up DMK, creates and backs up backup certificate
*** Change server name and enter complex passwords where required then save them to a key vault.
*** Use find-and-replace for foldername and servername for ease of use.
***
*** Ver		Date		Author			Changes
*** 1.0		13/11/2019	Alex Stuart		Initial version
***
************************************************************************************************************************************/

-- Backup SMK
BACKUP SERVICE MASTER KEY
TO FILE = '\\foldername\DatabaseCertAndKeys\servername\servername_SMK.key'
ENCRYPTION BY PASSWORD = ''

-- Create DMK
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = ''

-- Backup DMK
BACKUP MASTER KEY
TO FILE = '\\foldername\DatabaseCertAndKeys\servername\servername_DMK.key'
ENCRYPTION BY PASSWORD = 'pw'

-- Create Backup Certificate
CREATE CERTIFICATE [servername_BackupCert]
WITH SUBJECT = 'Backup Certificate for servername',
EXPIRY_DATE = '9999-12-31'

-- Backup Backup Certificate
BACKUP CERTIFICATE [servername_BackupCert]
TO FILE = '\\foldername\DatabaseCertAndKeys\servername\servername_BackupCert.cer'
WITH PRIVATE KEY
(
	FILE = '\\foldername\DatabaseCertAndKeys\servername\servername_BackupCert.key',
	ENCRYPTION BY PASSWORD = ''
)

SELECT *
FROM sys.certificates
