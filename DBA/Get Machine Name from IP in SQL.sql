/*****************************Original Code****************************************
declare @IP as varchar(15)
declare @cmd as varchar(1000) 
set @IP='172.20.152.8' 
SET @cmd = 'ping -a -n 1 ' + @IP 
Create Table #Output (Output varchar(150) default(''))
INSERT INTO #Output 
EXEC xp_cmdshell @cmd 
Begin try 
Select top 1 Replace(LEFT([Output],CHARINDEX('[', [output])-2),'Pinging ','') as HostName from #Output where Output is not null 
End Try 
Begin catch 
Select 'Host name for:' + @IP +' could not be find'
End catch 
drop table #Output
***********************************************************************************/
alter proc dbo.P_IP_To_Name @IP varchar(15) = '192.168.2.10', @MachineName varchar(100) output
as
	set nocount on
	declare @cmd as varchar(1000) 
	set @cmd = 'ping -a -n 1 ' + @IP 
	declare @Output table(Output varchar(150) default(''))
	insert @Output exec xp_cmdshell @cmd
	--Create Table #Output (Output varchar(150) default(''))
	delete @Output where left(coalesce(Output, ''), 8) <> 'Pinging '
	--select * from @Output
	Begin try
		if (1 = (select count(*) from @Output))
			set @MachineName = (Select replace(left([Output],charindex('[', [output])-2),'Pinging ','') as HostName from @Output)--where Output is not null and left(Output, 8) = 'Pinging '
		else
			set @MachineName = null
	End Try 
	Begin catch 
		--Select 'Host name for:' + @IP +' could not be found'
		set @MachineName = null
	End catch 


go

declare @MachineName varchar(100)
exec dbo.P_IP_To_Name '192.168.2.10', @MachineName output
select @MachineName
