# Simple Guide: Backing Up and Restoring MySQL Databases with `mysqldump`

This guide explains **how to back up and restore your MySQL databases and tables** using `mysqldump` and standard Linux commands—all in a friendly, beginner-friendly way.

---

## 1. Full Database Backup (Compressed)

**Command:**
sudo mysqldump employees | gzip > employees_full_backup.sql.gz
ls -lh employees_full_backup.sql.gz



**What it does:**
- `sudo mysqldump employees`: Connects to MySQL and exports (**backs up**) the entire contents and structure of the `employees` database.
- `| gzip`: Compresses the output "on the fly" to save disk space.
- `> employees_full_backup.sql.gz`: Saves the compressed backup file in your current folder with that name.
- `ls -lh ...`: Shows the file’s size so you can confirm it worked.

**Why use this?**
- Saves space by compressing the data
- Helps store backups more efficiently and safely

---

## 2. Partial Table Backup (One or More Tables)

**Command:**
sudo mysqldump employees employees departments > employees_partial_backup.sql
ls -lh employees_partial_backup.sql



**What it does:**
- `sudo mysqldump employees employees departments`: Backs up ONLY the `employees` and `departments` tables from the `employees` database (not the whole DB).
- `> employees_partial_backup.sql`: Saves the backup as a plain text file.
- `ls -lh ...`: Lets you check the size and presence of your backup file.

**Why use this?**
- Useful if you don’t need a backup of the entire database—just a few key tables.

---

## 3. Restore Backups

### a. Restore a Full (Compressed) Database Backup

**Command:**
gunzip < employees_full_backup.sql.gz | sudo mysql employees



**What it does:**
- `gunzip < ...`: Decompresses your backup file
- `| sudo mysql employees`: Directly restores the backup into the existing `employees` database

**Note:** The `employees` database **must already exist** before you run this restore command.

---

### b. Restore Partial Table Backup

**Command:**
sudo mysql employees < employees_partial_backup.sql



**What it does:**
- Loads the data from `employees_partial_backup.sql` into the (existing) `employees` database.
- Only restores the tables and data included in that partial backup.

---

## Key Points

- **Full backup**: Use when you want a complete copy of a database.
- **Partial (table) backup**: Use when you only want specific tables.
- Always **make sure the database exists** before restoring.
- Compression (`gzip`) reduces storage needs for big backups.

---

**Example Workflow:**
1. Make a backup (full or partial) before an upgrade or risky change.
2. If something goes wrong, restore the relevant backup file.
3. Use `ls -lh` to confirm files are present and sized correctly.

---

**That’s it! With these commands, you can easily protect and restore your MySQL data whenever needed.**