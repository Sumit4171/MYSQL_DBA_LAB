--Master-Slave Replication (Binary Log)


--1: Prepare the Current MySQL Instance as Master
     --already running MySQL on Ubuntu (let's say this is the Master).

    --Edit MySQL config file:
    sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

    --Find and change or add these lines:
    server-id = 1
    log_bin = /var/log/mysql/mysql-bin.log
    binlog_do_db = employees   # only if you want to replicate a specific database
    bind-address = 0.0.0.0     # optional: allows external slave to connect
    --save and exit (Ctrl + X, then Y, then Enter)


--2. Restart MySQL:
    sudo systemctl restart mysql

--3. Create Replication User
     sudo mysql 

    --Inside MySQL:
     CREATE USER 'repl_user'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_password';
    GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
    FLUSH PRIVILEGES;

--4. Lock Master and Take Note of Status:
     USE employees;
     FLUSH TABLES WITH READ LOCK;
    SHOW MASTER STATUS;
    -- unlock the tables after taking backup from another another terminal (unlock tables; should be used in same session from where  tables are locked)


    --backup the employees database (in another terminal)
      mysqldump -u root -p --databases employees --master-data=2 > employees_replication.sql



------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000001 |      866 | employees    |                  |                   |
+------------------+----------+--------------+------------------+-------------------+



--Run Second MySQL Instance on Same Ubuntu server
   --You can install a second MySQL instance and run it on a different port like 3307

   --Overview

       --A. Copy MySQL config and data directory for the new instance.

       --B. Change the port and paths to avoid conflict.

       --C. Set server-id = 2 for the slave.

       --D. Set up replication.

       --E. Start and manage both instances independently.

    --Prerequisites
        --You must already have:

        --MySQL installed on Ubuntu (Master runs on default port 3306).

        --Root or sudo access.   



     --1. Create directories for the second instance   
          sudo mkdir /etc/mysql-slave
          sudo mkdir /var/lib/mysql-slave
          sudo mkdir /var/log/mysql-slave

          --Set ownership of the directory to mysql user and group
          sudo chown mysql:mysql /var/log/mysql-slave


    --2.  Copy configuration and modify for port 3307
          sudo cp -r /etc/mysql/mysql.conf.d /etc/mysql-slave/
          sudo cp /etc/mysql/my.cnf /etc/mysql-slave/

        --Modify the slave’s configuration file
          sudo nano /etc/mysql-slave/my.cnf

          --Update:
          !includedir /etc/mysql-slave/mysql.conf.d/ 
        
         --Now edit the main MySQL config:
          sudo nano /etc/mysql-slave/mysql.conf.d/mysqld.cnf

        --Update these:
        [mysqld]
         port = 3307
         datadir = /var/lib/mysql-slave
        socket = /var/run/mysqld/mysqld_slave.sock
        pid-file = /var/run/mysqld/mysqld_slave.pid
        log-error = /var/log/mysql-slave/error.log
        server-id = 2
        relay_log = /var/log/mysql-slave/mysql-relay-bin
        skip-networking = 0
        bind-address = 0.0.0.0


    --3. Initialize new data directory
        sudo mysqld --initialize-insecure --datadir=/var/lib/mysql-slave --user=mysql

    --4. Create a systemd service for slave
        sudo cp /lib/systemd/system/mysql.service /etc/systemd/system/mysql-slave.service

        --Edit:
        sudo nano /etc/systemd/system/mysql-slave.service

        --Change lines:
        ExecStart=/usr/sbin/mysqld --defaults-file=/etc/mysql-slave/my.cnf

        --Save and reload systemd:
         sudo systemctl daemon-reexec
         sudo systemctl daemon-reload

    --5. Start slave MySQL instance
         sudo systemctl start mysql-slave
        sudo systemctl enable mysql-slave

        --Verify it:
        mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p

    --6.Set up replication on this slave
            --import to slave:
             mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p < employees_replication.sql

    --7.Configure replication in slave
        --Log in to the slave instance:
        mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p

        --Set master details (replace host/position from SHOW MASTER STATUS of master):
        CHANGE MASTER TO
        MASTER_HOST='192.168.217.131',
        MASTER_PORT=3306,
        MASTER_USER='repl_user',
        MASTER_PASSWORD='repl_password',
        MASTER_LOG_FILE='mysql-bin.000001',
        MASTER_LOG_POS=866;

        START SLAVE;

        --Check status:(it must be Slave_IO_Running: Yes, Slave_SQL_Running: Yes, otherwise there is a problem)
        SHOW SLAVE STATUS\G

    --8.Now You Have:
         --Master MySQL running on port 3306
         --Slave MySQL running on port 3307 on the same Ubuntu machine    
  

    --9.Test it
        -- On Master:
        USE employees;
        INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
        VALUES (6000001, '1890-05-15', 'Ray', 'Doe', 'F', '2025-04-10');


        -- On Slave:
       SELECT * FROM employees.employees WHERE emp_no = 6000001;



    --10 Test Failure Handling (To simulate failure:)
         STOP SLAVE SQL_THREAD;

        --Make changes on master:
        USE employees;
        INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
        VALUES (6000004, '1890-08-15', 'Daisy', 'ox', 'F', '2022-04-10');

       --Restart slave:
         START SLAVE;
         --Binlogs will catch up and apply changes during the downtime.
        SELECT * FROM employees.employees WHERE emp_no = 6000004;








-- GTID-Based Replication Setup

--Safe Plan to Enable GTID on an Active Replication Setup

--Current Setup:
--Master (3306) — Binary Log-based -->  GTID-Based Replication 

--Slave (3307) — Binary Log-based, working fine--> GTID-Based Replication 

-- want to:



-- Required Steps to Transition to GTID on Master Safely

--1. Update the master config (mysqld.cnf on 3306):

     sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

     enforce_gtid_consistency = ON
    gtid_mode = ON
    log_slave_updates = ON
    binlog_format = ROW
    --Keep server-id, log_bin, and binlog_do_db as-is.
    --These changes do NOT break existing binary log-based slaves.

--2.Restart the Master MySQL (3306):    
    sudo systemctl restart mysql

--3 Confirm GTID Settings Took Effect:
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'enforce_gtid_consistency';
    SHOW VARIABLES LIKE 'binlog_format';

--4 Stop Replication on Slave (3307)
    --Log in to MySQL on master-slave (port 3307)
          mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p
    -- stop replication:
        STOP SLAVE;

--5 Edit the Slave Config
    sudo nano /etc/mysql-slave/mysql.conf.d/mysqld.cnf
    -- add or update the following
       server-id = 2
       gtid_mode = ON
       enforce_gtid_consistency = ON
       log_slave_updates = ON
       log_bin = /var/log/mysql/mysql-bin.log
       binlog_format = ROW
       relay_log = /var/log/mysql/mysql-relay-bin
    -- Save and exit.

--6 Restart the Slave MYSQL--SLAVE (3307)
    sudo systemctl restart mysql-slave

--7 Confirm GTID is Enabled on Slave
    mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock -p
    
    SHOW VARIABLES LIKE 'gtid_mode';
    SHOW VARIABLES LIKE 'enforce_gtid_consistency';
    SHOW VARIABLES LIKE 'log_slave_updates';
    SHOW VARIABLES LIKE 'binlog_format';

--8  Reset and Reconfigure Replication with GTID
     RESET SLAVE ALL;

    CHANGE MASTER TO
    MASTER_HOST='192.168.217.131',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_password',
    MASTER_AUTO_POSITION = 1;

    START SLAVE;

--9 Check Slave Status
    SHOW SLAVE STATUS\G



    USE employees;
        INSERT INTO employees (emp_no, birth_date, first_name, last_name, gender, hire_date)
        VALUES (2000002, '1240-02-15', 'TWO', 'TEST', 'M', '2000-04-04');


          SELECT * FROM employees.employees WHERE emp_no = 2000002;



