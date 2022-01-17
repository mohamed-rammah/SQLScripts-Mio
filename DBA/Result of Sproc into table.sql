select * into ZZZZ
from (exec sp_readerrorlog)


sp_configure 'Show Advanced Options', 1
GO
RECONFIGURE
GO
sp_configure 'Ad Hoc Distributed Queries', 1
GO
RECONFIGURE
GO

/*
you have to create table as using select * into will result in this error
Msg 11520, Level 16, State 1, Procedure sp_describe_first_result_set, Line 1 [Batch Start Line 16]
The metadata could not be determined because statement 'exec sys.xp_readerrorlog @p1' in procedure 'sp_readerrorlog' invokes an extended stored procedure.
*/
if object_id('tmp.ErrorLog', 'U') is not null
	drop table tmp.ErrorLog
go
create table tmp.ErrorLog
(
LogDate datetime not null
,ProcessInfo varchar(1000) not null
,Text varchar(8000) not null
)
go
insert tmp.ErrorLog
select * from openrowset('SQLOLEDB', 'Server=HRLINSYNC;Trusted_Connection=yes;', 'exec sys.sp_readerrorlog')

SELECT * FROM tmp.ErrorLog


select * from openrowset('SQLOLEDB', 'Server=HRLINSYNC;Trusted_Connection=yes;', 'select * from Repositorydb.[dbo].[CBSPayee]')


/*
SELECT  * 
FROM    OPENROWSET ('SQLOLEDB','Server=HRLINSYNC;TRUSTED_CONNECTION=YES','set fmtonly off exec master.dbo.sp_who')
AS tbl
*/