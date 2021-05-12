/*********************************************************************************************
*** Batch Delete
*** 
*** Skeleton script for a batch deletion activity.
*** Batch size and the amount of/requirement for delay must be tested.
*** Infrequently or lightly used databases may be tolerant of large batch sizes and no
*** delay, highly concurrent OLTP databases may require small batches and seconds of delay.
***
*** Ver		Date		Author
*** 1.0		08/03/17	Alex Stuart
*** 
**********************************************************************************************/


DECLARE @rowcount BIGINT = 0;
DECLARE @batchsize BIGINT = 10000;

WHILE @rowcount < 2000000
BEGIN
	DELETE a
	FROM
		(SELECT TOP (@batchsize) *
		FROM dbo.tablename
		WHERE keyvalue < '15000000'
		ORDER BY leyvalue ASC) a

	SET @rowcount = @rowcount + @@ROWCOUNT

--  PRINT @rowcount

--  WAITFOR DELAY '00:00:01'

END
