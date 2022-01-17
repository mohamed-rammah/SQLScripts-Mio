SELECT 
 name
,type
,SUM(single_pages_kb + multi_pages_kb) AS MemoryUsedInKB
FROM sys.dm_os_memory_clerks 
GROUP BY name, type
ORDER BY SUM(single_pages_kb + multi_pages_kb) DESC

 