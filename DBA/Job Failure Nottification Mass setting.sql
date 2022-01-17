use msdb;
go
if exists (select * from sysjobs where enabled = 1 and notify_level_email = 0)
begin
declare @operator_id int = (select id from sysoperators where name = 'mohamed' and email_address is not null);
if @operator_id > 0 
	update sysjobs set notify_level_email = 2, notify_email_operator_id = @operator_id where enabled = 1 and notify_level_email = 0
end