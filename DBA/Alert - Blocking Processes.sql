--(1) create the job to send the email (no scheduling as it will fire based on alert)
USE [msdb]
GO

/****** Object:  Job [Blocking Info Email]    Script Date: 2020-06-12 9:50:32 AM ******/
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Blocking Info Email', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Mohamed', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Email Blocking Info]    Script Date: 2020-06-12 9:50:33 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Email Blocking Info', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @Subject varchar(200) = ''Blocking Info on server '' + @@servername;
declare @tableHTML varchar(2000) = 
N''<H1>Blocking Info</H1>'' +  
N''<table border="1">'' +  
N''<tr bgcolor=yellow><th>session_id</th><th>blocked_session_login</th><th>Blocked_Query</th>'' +  
N''<th>start_time</th><th>command</th><th>DB</th>'' +  
N''<th>wait_type</th><th>wait_time</th><th>blocking_session_id</th><th>blocking_session_login</th><th>BlockingQuery</th></tr>'' +  
CAST ( ( SELECT td = A.session_id,'''', 
				td = suser_name(A.user_id),'''',
                td = C.text,'''',  
                td = start_time,'''',  
                td = command,'''',  
                td = db_name(database_id),'''',  
                td = wait_type,'''',  
                td = wait_time,'''',  
                td = blocking_session_id,'''',
				td = B.Login,'''',
				td = D.text,''''
            from sys.dm_exec_requests A
			join (select session_id,sql_handle,suser_name(user_id) Login from sys.dm_exec_requests) B
			on A.blocking_session_id = B.session_id
			outer apply sys.dm_exec_sql_text(A.sql_handle) C
			outer apply sys.dm_exec_sql_text(B.sql_handle) D
			where blocking_session_id > 0
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

--(2) create altert that will invoke job above
declare @job uniqueidentifier = (select job_id from msdb.dbo.sysjobs where name = 'Blocking Info Email')

/****** Object:  Alert [Proccesses Blocked Alert]    Script Date: 2020-06-12 9:51:57 AM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Proccesses Blocked Alert', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=900, 
		@include_event_description_in=1, 
		@notification_message=N'Blocking Alert', 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'General Statistics|Processes blocked||>|0', 
		@job_id=@job;
GO




/*

declare @Subject varchar(200) = 'Blocking Info on server ' + @@servername;
declare @tableHTML varchar(2000) = 
N'<H1>Blocking Info</H1>' +  
N'<table border="1">' +  
N'<tr bgcolor=yellow><th>session_id</th><th>blocked_session_login</th><th>Blocked_Query</th>' +  
N'<th>start_time</th><th>command</th><th>DB</th>' +  
N'<th>wait_type</th><th>wait_time</th><th>blocking_session_id</th><th>blocking_session_login</th><th>BlockingQuery</th></tr>' +  
CAST ( ( SELECT td = A.session_id,'', 
				td = suser_name(A.user_id),'',
                td = C.text,'',  
                td = start_time,'',  
                td = command,'',  
                td = db_name(database_id),'',  
                td = wait_type,'',  
                td = wait_time,'',  
                td = blocking_session_id,'',
				td = B.Login,'',
				td = D.text,''
            from sys.dm_exec_requests A
			join (select session_id,sql_handle,suser_name(user_id) Login from sys.dm_exec_requests) B
			on A.blocking_session_id = B.session_id
			outer apply sys.dm_exec_sql_text(A.sql_handle) C
			outer apply sys.dm_exec_sql_text(B.sql_handle) D
			where blocking_session_id > 0
            FOR XML PATH('tr'), TYPE   
) as nvarchar(max)) +  
N'</table>';  

set @tableHTML = replace(@tableHTML, '&lt;', '<');
set @tableHTML = replace(@tableHTML, '&gt;', '>');
set @tableHTML = replace(@tableHTML, '&amp;', '&');

exec msdb.dbo.sp_send_dbmail @profile_name = 'Holts'
,@recipients='Mohamed.Rammah@HoltRenfrew.com'
,@subject=@Subject
,@body=@tableHTML
,@body_format='HTML';

*/

/*
select A.session_id, suser_name(A.user_id) blocked_session_login, C.text Blocked_Query, start_time 
, command , db_name(database_id), wait_type, wait_time, blocking_session_id,B.Login blocking_session_login, D.text BlockingQuery
from sys.dm_exec_requests A
join (select session_id ,sql_handle ,suser_name(user_id) Login from sys.dm_exec_requests) B
on A.blocking_session_id = B.session_id
outer apply sys.dm_exec_sql_text(A.sql_handle) C
outer apply sys.dm_exec_sql_text(B.sql_handle) D
where blocking_session_id > 0
*/