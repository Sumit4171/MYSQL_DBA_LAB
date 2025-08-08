# MySQL Master-Slave and GTID Replication: A Friendly, Step-by-Step Guide

Learn how to set up classic master-slave replication and then migrate safely to GTID-based (modern, reliable) replication. This walkthrough assumes you're running MySQL on Ubuntu and want both master and slave on the same server (like for labs, demos, or learning!).

---

## 🟢 Part 1: Classic (Binary Log) Master-Slave Replication

### 1. Prepare the Master Server

#### Edit the MySQL config to support replication
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf


Add or set these lines:
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_do_db = employees # replicate only the 'employees' database
bind-address = 0.0.0.0 # (allows slave connections from outside)


**Why?**  
- Enables transaction logging so changes can be sent to a slave.
- `server-id`: Must be unique per server!
- `log_bin`: Turns on binary logging (needed for replication).
- `binlog_do_db`: Replicates only a specific database to keep things neat.

---

### 2. Restart MySQL to Apply Config
sudo systemctl restart mysql



---

### 3. Create a Replication User

sudo mysql

-- Inside MySQL prompt:
CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_password';
GRANT REPLICATION SLAVE ON . TO 'repl_user'@'%';
FLUSH PRIVILEGES;


**Why?**  
You never want to use root for replication. This dedicated user can read changes for syncing!

---

### 4. Take a Consistent Backup Snapshot

In MySQL:

USE employees;
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
-- (Note 'File' and 'Position' for later. Keep this session open!)


In another terminal:
mysqldump -u root -p --databases employees --master-data=2 > employees_replication.sql


**Why?**  
- `FLUSH TABLES WITH READ LOCK`: Pauses writes for a consistent snapshot.
- `SHOW MASTER STATUS;`: Shows where the slave should "catch up" after the initial restore.
- The dump file contains your data and info for replication start point.

---

### 5. Set Up the Slave Server (Second MySQL Instance on a New Port)

**Why run two instances?**  
- Lets you simulate a real replication setup on one Ubuntu box!

- Create required directories:
sudo mkdir /etc/mysql-slave
sudo mkdir /var/lib/mysql-slave
sudo mkdir /var/log/mysql-slave
sudo chown mysql:mysql /var/log/mysql-slave


- Copy configuration and update for port `3307`:
sudo cp -r /etc/mysql/mysql.conf.d /etc/mysql-slave/
sudo cp /etc/mysql/my.cnf /etc/mysql-slave/
sudo nano /etc/mysql-slave/my.cnf # update !includedir
sudo nano /etc/mysql-slave/mysql.conf.d/mysqld.cnf


Set these in `[mysqld]`:
port = 3307
datadir = /var/lib/mysql-slave
socket = /var/run/mysqld/mysqld_slave.sock
pid-file = /var/run/mysqld/mysqld_slave.pid
log-error = /var/log/mysql-slave/error.log
server-id = 2
relay_log = /var/log/mysql-slave/mysql-relay-bin
skip-networking = 0
bind-address = 0.0.0.0



- Initialize the new data directory:
sudo mysqld --initialize-insecure --datadir=/var/lib/mysql-slave --user=mysql



- Create a new systemd service:
sudo cp /lib/systemd/system/mysql.service /etc/systemd/system/mysql-slave.service
sudo nano /etc/systemd/system/mysql-slave.service

Change ExecStart line to point to: /usr/sbin/mysqld --defaults-file=/etc/mysql-slave/my.cnf
sudo systemctl daemon-reexec
sudo systemctl daemon-reload



- Start slave:
sudo systemctl start mysql-slave
sudo systemctl enable mysql-slave



---

### 6. Import Data & Set Up Replication On Slave

- Import the backup:
mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p < employees_replication.sql



- Configure replication:
mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p

CHANGE MASTER TO
MASTER_HOST='Your.Master.IP.or.Host',
MASTER_PORT=3306,
MASTER_USER='repl_user',
MASTER_PASSWORD='repl_password',
MASTER_LOG_FILE='mysql-bin.000001', -- from SHOW MASTER STATUS
MASTER_LOG_POS=866; -- ditto

START SLAVE;
SHOW SLAVE STATUS\G


Both `Slave_IO_Running` and `Slave_SQL_Running` should be `Yes`.

---

### 7. Test Replication

- Insert data on Master:
USE employees;
INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
VALUES (6000001, '1890-05-15', 'Ray', 'Doe', 'F', '2025-04-10');


- Check on Slave:
SELECT * FROM employees.employees WHERE emp_no = 6000001;


You should see the new row appear automatically!

---

### 8. Failure Handling Demo

- On slave, pause replication:
STOP SLAVE SQL_THREAD;


- Add data on master.
- Resume replication:
START SLAVE;


- Slave "catches up" with what it missed via logs.

---

## 🟢 Part 2: Migrating to GTID-Based Replication (Modern, Safer Approach)

**Why switch to GTID?**  
GTID (Global Transaction ID) makes failover, resync, and topology changes much easier—no more worrying about binlog file/position.

---

### 1. Update Master (3306) for GTID

Edit config:
enforce_gtid_consistency = ON
gtid_mode = ON
log_slave_updates = ON
binlog_format = ROW


Restart master:
sudo systemctl restart mysql


**Why?**  
- Enables GTID while not breaking existing replication.

---

### 2. Confirm GTID Is On

SHOW VARIABLES LIKE 'gtid_mode';
SHOW VARIABLES LIKE 'enforce_gtid_consistency';
SHOW VARIABLES LIKE 'binlog_format';



---

### 3. Update Slave (3307) for GTID

Stop replication:
STOP SLAVE;



Edit `/etc/mysql-slave/mysql.conf.d/mysqld.cnf` and add:
server-id = 2
gtid_mode = ON
enforce_gtid_consistency = ON
log_slave_updates = ON
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
relay_log = /var/log/mysql/mysql-relay-bin


Restart slave:
sudo systemctl restart mysql-slave



---

### 4. Reset and Point Slave to Master Using GTID

RESET SLAVE ALL;
CHANGE MASTER TO
MASTER_HOST='Your.Master.IP.or.Host',
MASTER_USER='repl_user',
MASTER_PASSWORD='repl_password',
MASTER_AUTO_POSITION = 1;
START SLAVE;


**Why?**  
Now the slave synchronizes transactions based on their global IDs rather than specific log coordinates—a much safer and more flexible approach!

---

### 5. Final Test: Data Propagation With GTID

Insert on master:
INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
VALUES (2000002, '1240-02-15', 'TWO', 'TEST', 'M', '2000-04-04');


Check on slave:
SELECT * FROM employees.employees WHERE emp_no = 2000002;


The new entry should appear almost instantly.

---

## 🔔 Why Use This Script?

- Builds hands-on experience with both classic and modern MySQL replication
- Lets you safely experiment all on one Ubuntu server
- Mirrors production-grade steps for MySQL admins
- GTID mode prepares you for automated failover and cluster operations

---

**Congratulations!**  
You now know how to turn your Ubuntu server into a real, multi-instance MySQL replication lab, and migrate from traditional to GTID-based replication—step by step, with explanations!