SELECT login_name, count(session_id) as session_count 
FROM sys.dm_exec_sessions 
GROUP BY login_name