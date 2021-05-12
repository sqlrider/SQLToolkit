/*******************************************************************************************************************
*** Create Azure SQL Database user
*** 
*** Create an Azure SQL Database user. The code - and resulting username - is different depending on whether
*** the tenant of the server is external (guest) or not
***
*** Ver		Date		Author
*** 1.0		16/07/19	Alex Stuart
*** 
********************************************************************************************************************/


-- 1. Create AAD user in Azure portal


-- 2. In SSMS, select the required database from the drop-down in the top left


-- 3a. If the user is from the same tenant as the server, run the following command

CREATE USER [user.name@ADTenant.com]
FROM EXTERNAL PROVIDER


-- 3b. If user is a guest from a different tenant, run the following command

CREATE USER [user.name_theirtenant.com#EXT#@currenttenant.onmicrosoft.com] 
FROM EXTERNAL PROVIDER


-- 4. Add user to db_datareader or other roles

ALTER ROLE db_datareader
-- ADD MEMBER [user.name@ADTenant.com]		-- if same tenant
ADD MEMBER [user.name_theirtenant.com#EXT#@currenttenant.onmicrosoft.com]	-- if guest tenant
