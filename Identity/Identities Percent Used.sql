/**************************************************************************************************
*** Identities Percent Used
*** 
*** Returns list of identity columns used in current database ordered by percent used descending. 
***
*** Ver		Date		Author
*** 1.0		09/04/2021	Alex Stuart
*** 
***************************************************************************************************/
WITH identities AS
(
	SELECT OBJECT_SCHEMA_NAME(c.[object_id]) + '.' + OBJECT_NAME(c.[object_id]) AS 'TableName',
		c.[name] AS 'ColumnName',
		t.[name] AS 'Type',
		IDENT_CURRENT(OBJECT_SCHEMA_NAME(c.[object_id]) + '.' + OBJECT_NAME(c.[object_id])) AS 'CurrentValue',
		CASE t.[name]
				WHEN 'bigint'
					THEN 9223372036854775807
				WHEN 'int'
					THEN 2147483647
				WHEN 'smallint'
					THEN 32767
				WHEN 'tinyint'
					THEN 255
				END AS 'Limit'
	FROM sys.all_columns c
	INNER JOIN sys.objects o
		ON c.[object_id] = o.[object_id]
	INNER JOIN sys.types t
		ON c.system_type_id = t.system_type_id
		AND c.system_type_id = t.user_type_id
	WHERE c.is_identity = 1
	AND o.[type] = 'U'
)
SELECT TableName,
	ColumnName,
	[Type],
	ISNULL(CurrentValue,0) AS 'CurrentValue',
	Limit,
	CASE 
		WHEN CurrentValue IS NULL THEN 0
        ELSE CAST((CurrentValue / Limit) * 100 AS DECIMAL(4,2))
	END AS 'PercentUsed' 
FROM identities
ORDER BY (CurrentValue / Limit) * 100 DESC
