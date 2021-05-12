/**************************************************************************************
*** Search Variables and Parameters
*** 
*** Search SSISDB variables and parameters for a search term.
***
*** Ver		Date		Author
*** 1.0		22/02/19	Alex Stuart
*** 
***************************************************************************************/

USE SSISDB
GO

DECLARE @search NVARCHAR(100)

SET @search = N'%searchterm%'

SELECT f.[name] AS 'Folder', p.[name] AS 'Project', ev.[value]
FROM catalog.environment_variables ev
INNER JOIN catalog.environments e
	ON ev.environment_id = e.environment_id
INNER JOIN catalog.environment_references er
	ON e.[name] = er.environment_name
INNER JOIN catalog.projects p
	ON er.project_id = p.project_id
INNER JOIN catalog.folders f
	ON f.folder_id = p.folder_id
WHERE CONVERT(NVARCHAR(MAX), ev.[value]) LIKE @search

SELECT f.[name] AS 'Folder', p.[name] AS 'Project', op.[object_name], op.parameter_name, op.design_default_value, op.default_value
FROM catalog.object_parameters op
INNER JOIN catalog.projects p
	ON op.project_id = p.project_id
INNER JOIN catalog.folders f
	ON p.folder_id = f.folder_id
WHERE CONVERT(NVARCHAR(MAX), op.design_default_value) LIKE @search
OR CONVERT(NVARCHAR(MAX), op.default_value) LIKE @search

