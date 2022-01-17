/**Clean up
drop table admin.Index_Usage_Stats;
drop table admin.Indexes_Unused;
**/
--=========================================== Index Usage Stats ====================================================
declare @schema varchar(10) = 'admin'
if schema_id(@schema) is null
	exec ('create schema ' + @schema + ' authorization dbo')
go
if object_id('admin.Index_Usage_Stats', 'U') is null
create table admin.Index_Usage_Stats
(
--ID int not null identity??
TS date not null default(current_timestamp)
,DB varchar(50) not null
,TBL varchar(100) not null
,INDX_ID int not null
,INDX_Name varchar(100) not null
,Rows int not null
,user_seeks int null
,user_scans int null
,user_lookups int null
,user_updates int null
,last_user_seek datetime2(0) null
,last_user_scan datetime2(0) null
,last_user_lookup datetime2(0) null
,last_user_update datetime2(0) null
,constraint PK_admin_Index_Usage_Stats primary key clustered (TS,DB,TBL,INDX_ID)
--,constraint UK_admin_Index_Usage_Stats unique nonclustered (DB, TBL, INDX_ID)
);
delete admin.Index_Usage_Stats where TS = cast(current_timestamp as date);
insert into admin.Index_Usage_Stats
(
--TS
DB
,TBL
,INDX_ID
,INDX_Name
,Rows
,user_seeks
,user_scans
,user_lookups
,user_updates
,last_user_seek
,last_user_scan
,last_user_lookup
,last_user_update
)
select
--current_timestamp
db_name(db_id()) DB
,object_name(A.object_id) [Table]
,A.index_id
,B.name index_name
,C.Rows
,user_seeks
,user_scans
,user_lookups
,user_updates
,last_user_seek
,last_user_scan
,last_user_lookup
,last_user_update
from sys.dm_db_index_usage_stats A
join sys.indexes B on A.object_id = B.object_id and A.index_id = B.index_id
join (select object_id, index_id, sum(rows) Rows from sys.partitions group by object_id, index_id) C
on A.object_id = C.object_id and A.index_id = C.index_id
where 1=1
and database_id = db_id()
and A.object_id in (select object_id from sys.tables where is_ms_shipped <> 1)  --**Filter for tables not created during SQL installation
and objectproperty(A.object_id, 'IsUserTable') = 1
and A.index_id > 0
and schema_name(objectproperty(A.object_id, 'SchemaID')) = 'dbo'
order by 1, 2, 3;
go
select * from admin.Index_Usage_Stats
--***** Indexed wihout scans but get updated
select * from admin.Index_Usage_Stats where user_seeks = 0 and user_scans = 0 and user_lookups = 0 and user_updates > 0
and TS = (select max(TS) from admin.Index_Usage_Stats);
go

--========================================== Unused Indexes ==========================================================
if object_id('admin.Indexes_Unused', 'U') is null
create table admin.Indexes_Unused
(
TS date not null default(current_timestamp)
,DB varchar(50) not null
,TBL varchar(100) not null
,INDX_ID int not null
,INDX_Name varchar(100) not null
,Rows int not null
,constraint PK_admin_Indexes_Unused primary key clustered (TS,DB,TBL,INDX_ID)
);
go
delete admin.Indexes_Unused where TS = cast(current_timestamp as date);
insert into admin.Indexes_Unused
(
--TS
DB
,TBL
,INDX_ID
,INDX_Name
,Rows
)
select 
db_name(db_id()) DB
,object_name(A.object_id) [Table]
,A.index_id
,A.name index_name
,B.Rows
from sys.indexes A
join (select object_id, index_id, sum(rows) Rows from sys.partitions group by object_id, index_id) B
on A.object_id = B.object_id and A.index_id = B.index_id
left join sys.dm_db_index_usage_stats C
on A.object_id = C.object_id and A.index_id = C.index_id
where C.index_id is null
and A.object_id in (select object_id from sys.tables where is_ms_shipped <> 1)  --**Filter for tables not created during SQL installation
and objectproperty(A.object_id, 'IsUserTable') = 1
and A.index_id > 0
and schema_name(objectproperty(A.object_id, 'SchemaID')) = 'dbo'
order by 1, 2, 3;
go
select * from admin.Indexes_Unused;


