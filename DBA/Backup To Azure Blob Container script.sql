declare @FileNm nvarchar(100) = N'SSAS_' + convert(varchar(15), getdate(), 112) + '_' + replace(convert(varchar(5), getdate(), 8), ':', '')
select @FileNm

declare @sql nvarchar(1000) = 'BACKUP DATABASE [SSAS] TO  URL = ''https://misr9ragrs.blob.core.windows.net/sql1/' + @FileNm + '.bak'' with init'

select @sql

exec(@sql)