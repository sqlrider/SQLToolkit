/**************************************************************************************
*** Database Mail Views
*** 
*** Queries to interrogate Database Mail views
***
*** Ver		Date		Author
*** 1.0		30/08/18	Alex Stuart
*** 
***************************************************************************************/

USE msdb
GO

-- All Items
SELECT mailitem_id, recipients, [subject], body, send_request_date, sent_account_id, sent_status, sent_date, last_mod_date
FROM dbo.sysmail_allitems
ORDER BY mailitem_id DESC

-- Failed items
SELECT mailitem_id, recipients, subject, send_request_date, sent_status, sent_date
FROM dbo.sysmail_faileditems
ORDER BY mailitem_id DESC

-- Event log
SELECT mailitem_id, log_id, log_date, description, last_mod_date
FROM dbo.sysmail_event_log
ORDER BY mailitem_id DESC

-- Sent items
SELECT *
FROM dbo.sysmail_sentitems
ORDER BY mailitem_id DESC

-- Unsent items
SELECT *
FROM dbo.sysmail_unsentitems

