/*********************************************************************************************
*** Cached Query Plan Costs
***
*** Lists (estimated) costs of query plans in query plan cache
***
*** Ver		Date		Author
*** 1.0		20/09/18	Grant Fitchey
***
***********************************************************************************************/

USE master
GO

WITH XMLNAMESPACES (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'),
TextPlans AS (
	SELECT CAST(detqp.query_plan AS XML) AS 'QueryPlan',
           detqp.dbid,
		   dest.[text]
    FROM sys.dm_exec_query_stats AS deqs
	CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
    CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle, deqs.statement_start_offset, deqs.statement_end_offset) AS detqp
	WHERE detqp.dbid = 5	-- Set specific database here
),
QueryPlans AS (
	SELECT RelOp.pln.value(N'@EstimatedTotalSubtreeCost', N'float') AS 'EstimatedCost',
           RelOp.pln.value(N'@NodeId', N'integer') AS 'NodeId',
           tp.dbid,
           tp.QueryPlan,
		   tp.[text]
    FROM TextPlans AS tp
    CROSS APPLY tp.queryplan.nodes(N'//RelOp')RelOp(pln)
)
SELECT qp.EstimatedCost, qp.[text]
FROM QueryPlans AS qp
WHERE qp.NodeId = 0
ORDER BY qp.EstimatedCost DESC
