/**************************************************************************************
*** List User Permissions
*** 
*** List server/database permissions
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
***************************************************************************************/


---- Server Permissions

USE master
GO

-- List roles
SELECT *
FROM sys.server_principals
WHERE [type] = 'R'

-- List role memberships
SELECT spri2.name AS 'Role Name', spri.name
FROM sys.server_principals spri
INNER JOIN sys.server_role_members sro
	ON spri.principal_id = sro.member_principal_id
INNER JOIN sys.server_principals spri2
	ON sro.role_principal_id = spri2.principal_id
ORDER BY sro.role_principal_id ASC

-- List all permissions
SELECT spri.principal_id, spri.name, spri.type_desc, spri.is_disabled, spri.modify_date, sper.class_desc, sper.major_id, sper.[permission_name], sper.state_desc, spri2.name AS 'Grantor'
FROM sys.server_principals spri
INNER JOIN sys.server_permissions sper
	ON spri.principal_id = sper.grantee_principal_id
INNER JOIN sys.server_principals spri2
	ON sper.grantor_principal_id = spri2.principal_id
ORDER BY spri.principal_id ASC



--- Database Permissions

USE DatabaseName
GO

-- List database roles
SELECT *
FROM sys.database_principals
WHERE [type] = 'R'

-- List role memberships
SELECT dpri2.name AS 'Role Name', dpri.name
FROM sys.database_principals dpri
INNER JOIN sys.database_role_members dro
	ON dpri.principal_id = dro.member_principal_id
INNER JOIN sys.database_principals dpri2
	ON dro.role_principal_id = dpri2.principal_id
ORDER BY dro.role_principal_id ASC


-- List all permissions


SELECT dpri.principal_id,
	dpri.name,
	dpri.type_desc,
	dpri.modify_date,
	dper.class_desc,
		CASE
		WHEN dper.major_id = 0 THEN NULL
		WHEN dper.major_id <> 0 THEN OBJECT_SCHEMA_NAME(dper.major_id)
	END AS 'Schema',
	CASE 
		WHEN dper.major_id = 0 THEN NULL
		WHEN dper.major_id <> 0 THEN OBJECT_NAME(dper.major_id)
	END AS 'Object',
	dper.[permission_name],
	dper.state_desc,
	dpri2.name AS 'Grantor'
FROM sys.database_principals dpri
INNER JOIN sys.database_permissions dper
	ON dpri.principal_id = dper.grantee_principal_id
INNER JOIN sys.database_principals dpri2
	ON dper.grantor_principal_id = dpri2.principal_id
ORDER BY dpri.principal_id ASC


SELECT d.[name] AS 'UserName', d.[type_desc] AS 'Type', d2.[name] AS 'Role'
FROM sys.database_principals d
LEFT OUTER JOIN sys.database_role_members r
ON d.principal_id = r.member_principal_id
LEFT OUTER JOIN sys.database_principals d2
ON d2.principal_id = r.role_principal_id
WHERE d.[type_desc] <> 'DATABASE_ROLE'


