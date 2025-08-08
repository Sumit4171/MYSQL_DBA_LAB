--sudo mysqldump employees creates a full logical backup of the employees database.
--| gzip compresses the backup to reduce file size.
--> employees_full_backup.sql.gz saves the compressed output in your current folder.
--ls -lh employees_full_backup.sql.gz shows the backup file with its size.
--This method is useful for saving space and storing backups safely.

sudo mysqldump employees | gzip > employees_full_backup.sql.gz
ls -lh employees_full_backup.sql.gz


--sudo mysqldump employees employees departments backs up only the employees and departments tables from the employees database.
--It creates a partial backup, not the full database.
--> employees_partial_backup.sql saves the backup file in your current directory.
--ls -lh employees_partial_backup.sql displays the file size and confirms its creation.
--This method is useful when you only need to back up specific tables.


sudo mysqldump employees employees departments > employees_partial_backup.sql
ls -lh employees_partial_backup.sql


--For restoring
--This decompresses the file and pipes it directly into MySQL.
--Again, the employees database must exist. 
gunzip < employees_full_backup.sql.gz | sudo mysql employees


--Restore partial table backup of  employees and department within employees database
-- will work if the database exist
sudo mysql employees < employees_partial_backup.sql










