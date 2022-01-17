use master;

if exists (select * from sys.syslogins where name = 'HOLTRENFREW\HRHLMRAMM')
	alter login [HOLTRENFREW\HRHLMRAMM] WITH NAME = [HOLTRENFREW\Mohamed.Rammah];

go

--******* clean up ********************************
declare @sql nvarchar(4000) = 'use ?; if exists (select * from sys.sysusers where name = ''oldname'') drop user oldname';
print @sql;
exec sp_msforeachdb @sql;

if exists (select * from sys.syslogins where name = 'oldname')
	drop login oldname;

if exists (select * from sys.syslogins where name = 'newname')
	drop login newname;
--********************************************************

create login oldname with password = '', check_policy=off;
go
select * from sys.syslogins where name = 'oldname';  --**password = null, dbname = master
go
use testdb;
go
create user oldname for login oldname;
alter role db_datareader add member oldname;
select * from sys.sysusers;
go

use master;
go
alter login oldname with name = newname;
go
select * from sys.syslogins where name = 'newname';  --**password = null, dbname = master
go
use testdb;
go
select * from sys.sysusers;
go
--to fix this
declare @sql nvarchar(4000) = 'use ?; if exists (select * from sys.sysusers where name = ''oldname'') alter user oldname with name = newname';
print @sql;
exec sp_msforeachdb @sql;
go
select * from sys.sysusers;