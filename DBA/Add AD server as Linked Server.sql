--https://www.mssqltips.com/sqlservertip/2580/querying-active-directory-data-from-sql-server/
--**
go
USE [master]
GO 
EXEC master.dbo.sp_addlinkedserver @server = N'ADSI', @srvproduct=N'Active Directory Service Interfaces', @provider=N'ADSDSOObject', @datasrc=N'adsdatasource'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'ADSI',@useself=N'False',@locallogin=NULL,@rmtuser=N'HOLTRENFREW\HRL_SVC_SQL',@rmtpassword='xxxxxxxxx'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'collation compatible',  @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'data access', @optvalue=N'true'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'dist', @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'pub', @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'rpc', @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'rpc out', @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'sub', @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'connect timeout', @optvalue=N'0'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'collation name', @optvalue=null
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'lazy schema validation',  @optvalue=N'false'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'query timeout', @optvalue=N'0'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'use remote collation',  @optvalue=N'true'
GO 
EXEC master.dbo.sp_serveroption @server=N'ADSI', @optname=N'remote proc transaction promotion', @optvalue=N'true'


Querying Active Directory
Once the linked server is created we can now setup our query to return the information we need. 
First, you'll need to ask your Network/Systems Administrator for your LDAP info then we can continue to the query.  
Here is how the LDAP connection is broken down: 
For our example it looks like this: LDAP://DOMAIN.com/OU=Players,DC=DOMAIN,DC=com 
LDAP://Domain.com - is the name of a domain controller 
/OU=Players - this is the Organization Unit, in our case (Players) 
,DC - this is the Domain Name broken up by domain and extension name 
So....LDAP://DomainControllerName.com/OU=OrganizationalUnit,DC=DOMAIN,DC=NAME 
According to the problem, this user needs to return the companies email addresses and phone numbers. To do this we can use the code below: 
(note - you will need to change your domain information for this to work) 
SELECT * FROM OpenQuery ( 
  ADSI,  
  'SELECT displayName, telephoneNumber, mail, mobile, facsimileTelephoneNumber 
  FROM  ''LDAP://DOMAIN.com/OU=Players,DC=DOMAIN,DC=com'' 
  WHERE objectClass =  ''User'' 
  ') AS tblADSI
ORDORDER BY displayname
As you can see this query will return Active Directory's Display Name, Telephone Number, Email Address, Mobile Number, and Fax Number. Also note, that when you query Active Directory it actually creates the SELECT statement backwards. I started the SELECT statement with SELECT displayname... but in the results pane it displayed displayName last as shown below.
 
If you wanted to view more columns for each user we can use the below code to display fields such as: FirstName, Office, Department, Fax, Mobile, Email, Login, Telephone, Display Name, Title, Company, Pager, Street Address, and more. 
SELECT * FROM OpenQuery
  ( 
  ADSI,  
  'SELECT streetaddress, pager, company, title, displayName, telephoneNumber, sAMAccountName, 
  mail, mobile, facsimileTelephoneNumber, department, physicalDeliveryOfficeName, givenname 
  FROM  ''LDAP://DOMAIN.com/OU=Players,DC=DOMAIN,DC=com''
  WHERE objectClass =  ''User'' 
  ') AS tblADSI
ORDER BY displayname