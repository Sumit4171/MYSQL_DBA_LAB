# Simple MySQL Installation Script – Explained

This guide explains, step by step (and with practical examples), what each command in your MySQL installation and setup script does.  
Great for beginners or anyone learning how to set up MySQL Server on Ubuntu!

---

## Script Step-by-Step

### 1. Check Linux Distribution Info

lsb_release -a


**What it does:**  
Prints your Linux version info (for example: Ubuntu 22.04 LTS).  
**Why:**  
Good to confirm OS before installing or troubleshooting MySQL.

**Example output:**
Distributor ID: Ubuntu
Description: Ubuntu 22.04.4 LTS
Release: 22.04
Codename: jammy



---

### 2. Show Current Directory

pwd


**What it does:**  
Prints the "present working directory" (your current folder).  
**Why:**  
Useful if you want to know or show where you are in the filesystem before running scripts.

**Example:**
/home/ubuntu


---

### 3. Update Package Lists

sudo apt update


**What it does:**  
Updates Ubuntu’s internal list of available software versions and updates.  
**Why:**  
Ensures you’ll get the latest security and feature updates for MySQL and dependencies.

---

### 4. Install MySQL Server

sudo apt install mysql-server -y


**What it does:**  
Downloads and installs the MySQL database server and tools.  
**Why:**  
This is the main program you want to run databases.

`-y` means "Automatically answer yes to any questions."

---

### 5. Start the MySQL Service

sudo systemctl start mysql


**What it does:**  
Starts the MySQL service, so your server is running and ready to accept connections.  
**Example:**  
If you try to connect via `mysql` command, now it will work.

---

### 6. Enable MySQL to Start at Boot

sudo systemctl enable mysql


**What it does:**  
Sets up MySQL to automatically start every time the server restarts.  
**Why:**  
So your database is always up after reboots—no manual start needed.

---

### 7. Run MySQL Secure Installation

sudo mysql_secure_installation


**What it does:**  
Interactive wizard to secure your server:
- Set a strong root password
- Remove anonymous users
- Remove the test database
- Disallow remote root login

**Why:**  
Strongly recommended for better security!

**Example steps:**  
- "Set root password?" [Y/n]: Y  
- "Remove anonymous users?" [Y/n]: Y  
- ...

---

### 8. Check MySQL Service Status

sudo systemctl status mysql


**What it does:**  
Shows the current status (running, stopped, errors, etc.) of MySQL.

**Example output:**
● mysql.service - MySQL Community Server
Loaded: loaded (/lib/systemd/system/mysql.service; enabled)
Active: active (running)



---

## Summary Table

| Command                        | What it Does (Simple)                        |
| ------------------------------ |:---------------------------------------------|
| `lsb_release -a`               | Shows Linux version                          |
| `pwd`                          | Prints your current folder                   |
| `sudo apt update`              | Updates list of available packages           |
| `sudo apt install mysql-server -y` | Installs MySQL server                   |
| `sudo systemctl start mysql`   | Starts the MySQL database server             |
| `sudo systemctl enable mysql`  | Auto-start MySQL on every boot               |
| `sudo mysql_secure_installation` | Secures your DB (sets password, etc)      |
| `sudo systemctl status mysql`  | Shows if MySQL is running or has problems    |

---

## What Happens Next?

After running this script:
- MySQL Server is installed, running, and secure
- You can connect to MySQL using:
sudo mysql -u root -p



**Congratulations!**  
Your Ubuntu server is now ready for database projects.
