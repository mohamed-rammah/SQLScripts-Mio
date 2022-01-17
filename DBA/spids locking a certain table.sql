select object_id('dbo.tablename')
go
select * from sys.dm_tran_locks
where resource_type = 'object'
and resource_associated_entity_id = 2137227560