/***************************************************************************************************************************
*** Recent Project Modifications
*** 
*** Query to find recently modified SSISDB projects.
***
*** Ver		Date		Author
*** 1.0		14/09/18	Alex Stuart
*** 
****************************************************************************************************************************/

SELECT f.name AS 'FolderName', p.name AS 'ProjectName', p.created_time
FROM catalog.projects p
INNER JOIN  catalog.folders f
	ON p.folder_id = f.folder_id
WHERE p.created_time > '2020-08-26 15:32:37.6886094 +01:00'
ORDER BY p.created_time DESC


SELECT f.name AS 'FolderName', p.name AS 'ProjectName', p.created_time, p.last_deployed_time
FROM catalog.projects p
INNER JOIN  catalog.folders f
	ON p.folder_id = f.folder_id
WHERE p.created_time < '2020-08-26 15:32:37.6886094 +01:00'
AND p.last_deployed_time > '2020-08-26 15:32:37.6886094 +01:00'
ORDER BY p.last_deployed_time DESC
