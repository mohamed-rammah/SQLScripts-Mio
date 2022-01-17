with worst_queries
as
(
select top 10 * from sys.dm_exec_query_stats
order by total_worker_time/execution_count desc
)
select * from worst_queries A
cross apply sys.dm_exec_sql_text (A.sql_handle)
order by A.total_worker_time/A.execution_count desc;