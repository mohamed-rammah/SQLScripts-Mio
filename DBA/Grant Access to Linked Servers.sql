--this script will allow all users to access linked servers
Use MASTER
GRANT EXECUTE ON SYS.XP_PROP_OLEDB_PROVIDER TO public;