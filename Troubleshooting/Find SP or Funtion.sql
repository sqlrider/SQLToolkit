/**************************************************************************************
*** Find SP or Function
*** 
*** Finds a procedure/function with given text in its definition
***
*** Ver		Date		Author
*** 1.0		12/06/19	Alex Stuart
*** 
***************************************************************************************/

USE [databasename]
GO

SELECT DISTINCT o.name, o.type_desc, sm.[definition]
FROM sys.sql_modules sm
INNER JOIN sys.objects o
	ON sm.object_id = o.object_id
WHERE sm.[definition] Like '%searchfilter%';


