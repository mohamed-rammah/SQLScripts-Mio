---------------------------------------------------------------------------
--Below Query provides information about the active full text catalogs 
--on the current database

SELECT
 ct.name
,ct.is_paused
,ct.status_description
,ct.row_count_in_thousands
,OBJECT_NAME(ipop.table_id)astable_name
,ipop.population_type_description
,ipop.is_clustered_index_scan
,ipop.status_description
,ipop.completion_type_description
,ipop.queued_population_type_description
,ipop.start_time
,ipop.range_count
FROM sys.dm_fts_active_catalogs ct
CROSS JOIN sys.dm_fts_index_population ipop
WHERE ct.database_id=ipop.database_id
  AND ct.catalog_id=ipop.catalog_id
  AND ct.database_id=DB_ID()

---------------------------------------------------------------------------