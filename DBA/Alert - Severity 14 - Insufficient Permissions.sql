use msdb;
go
exec msdb.dbo.sp_add_alert @name=N'Severity 14 - Insufficient Permissions', 
		@message_id=0, 
		@severity=14, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1
go
exec msdb.dbo.sp_add_notification @alert_name=N'Severity 14 - Insufficient Permissions', @operator_name=N'Mohamed', @notification_method = 1
