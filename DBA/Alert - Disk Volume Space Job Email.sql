--(0) Create Operator mohamed if does not exist
use msdb;
go
if not exists (select * from dbo.sysoperators where name = 'mohamed')
exec msdb.dbo.sp_add_operator @name=N'mohamed', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'Mohamed.Rammah@HoltRenfrew.com', 
		@category_name=N'[Uncategorized]'

go
--(1) create the job to send the email (no scheduling as it will fire based on alert)
/****** Object:  Job [Disk Volume Alert Email]    Script Date: 2020-06-12 9:50:32 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2020-06-12 9:50:32 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Disk Volume Alert Email', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Disk Volume Alert Email', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Mohamed', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Blocking Info]    Script Date: 2020-06-12 9:50:33 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Disk Drive Info', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @Subject varchar(200) = ''Disk Drive Space Status on server '' + @@servername;
declare @tableHTML varchar(2000) = 
N''<H1>Server Drive Space Info</H1>'' +  
N''<table border="1">'' +  
N''<tr bgcolor=yellow><th>Server</th><th>Volume_Drive</th><th>Free_Space_GB</th>'' +  
N''<th>Total_Space_GB</th><th>Percent_Free</th></tr>'' +  
CAST ( ( SELECT distinct td = @@servername,'''', 
				td = B.volume_mount_point,'''',
                td = B.available_bytes/1024/1024/1024,'''',  
                td = B.total_bytes/1024/1024/1024,'''',  
                td = cast(B.available_bytes*100/total_bytes as varchar(2)) + '' %'',''''
			from sys.master_files A
			cross apply sys.dm_os_volume_stats (A.database_id, A.file_id) B
			order by B.volume_mount_point
            FOR XML PATH(''tr''), TYPE   
) as nvarchar(max)) +  
N''</table>'';  

set @tableHTML = replace(@tableHTML, ''&lt;'', ''<'');
set @tableHTML = replace(@tableHTML, ''&gt;'', ''>'');
set @tableHTML = replace(@tableHTML, ''&amp;'', ''&'');

exec msdb.dbo.sp_send_dbmail @profile_name = ''Holts''
,@recipients=''Mohamed.Rammah@HoltRenfrew.com''
,@subject=@Subject
,@body=@tableHTML
,@body_format=''HTML'';', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


--(2) Add schedule

declare @job_id uniqueidentifier = (select job_id from dbo.sysjobs where name = 'Disk Volume Alert Email')
declare @schedule_id int
if (
@job_id is not null 
and not exists (select * from sysschedules where name = 'Disk Volume Alert Email Sched')
and not exists (select * from sysjobschedules where job_id = @job_id)
)

exec dbo.sp_add_jobschedule @job_id = @job_id, @name=N'Disk Volume Alert Email Sched', 
		@enabled=1, 
		@freq_type=8,		-- Weekly (8)  Daily(4)
		@freq_interval=32, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20210206, 
		@active_end_date=99991231, 
		@active_start_time=140000,	--02:00 PM
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT

go

--(3) Manually Run job
sp_start_job @job_name='Disk Volume Alert Email'