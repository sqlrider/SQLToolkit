
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_CreateBaseTableFG]
AS
BEGIN

CREATE TABLE dbo.InvoicesPT_FG
(
	InvoiceID		INT IDENTITY(1,1) NOT NULL,
	InvoiceDate		DATETIME NOT NULL,
	InvoiceMonth	VARCHAR(10),
	InvoiceData		VARCHAR(50),
	CONSTRAINT pk_InvoiceID_PT_FG PRIMARY KEY CLUSTERED (InvoiceID, InvoiceDate)
) ON ps_Monthly_FG(InvoiceDate)

CREATE NONCLUSTERED INDEX ncx_InvoicesPT_FG_Month ON dbo.InvoicesPT_FG (InvoiceMonth)

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-01-15 12:34:56.777', 'January', 'Winter tools'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-02-15 12:34:56.777', 'Febuary', 'Thermal Jacket'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-03-15 12:34:56.777', 'March', 'Gardening Tools'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-04-15 12:34:56.777', 'April', 'Practical Joke Kit'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-05-15 12:34:56.777', 'May', 'Summer Shorts'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-06-15 12:34:56.777', 'June', '5W30 Motor Oil'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-07-15 12:34:56.777', 'July', 'Smoothie Maker'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-08-15 12:34:56.777', 'August', 'Ice Machine'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-09-15 12:34:56.777', 'September', 'Lightweight Jacket'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-10-15 12:34:56.777', 'October', 'Spooky Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-11-15 12:34:56.777', 'November', 'Mulled Wine'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2016-12-15 12:34:56.777', 'December', 'Christmas Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2017-01-15 12:34:56.777', 'Jan2017', 'New Year Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2017-02-15 12:34:56.777', 'Feb2017', 'New Snow Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2017-03-15 12:34:56.777', 'Mar2017', 'New Spring Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

INSERT INTO dbo.InvoicesPT_FG (InvoiceDate, InvoiceMonth, InvoiceData)
SELECT TOP 1000 '2017-04-15 12:34:56.777', 'Apr2017', 'More Spring Stuff'
FROM sys.objects o1
CROSS JOIN sys.objects o2

END



GO


