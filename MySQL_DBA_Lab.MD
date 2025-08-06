# MySQL DBA Lab: User Access, Replication, and Performance Monitoring (PMM)

Welcome! This project is your practical, hands-on MySQL DBA and monitoring lab. It demonstrates:
- Creating different types of MySQL users and managing privileges
- Installing MySQL securely on Ubuntu (VM or server)
- Setting up multi-instance MySQL and preparing for replication
- Deploying Percona Monitoring and Management (PMM) for real database observability

---

## 1. MySQL User Access & Privileges

Every MySQL user is defined by **username** and **host**.  
This allows you to control exactly where and how users can access the database.

| Access Type         | Example User                | Description                                    |
|---------------------|----------------------------|------------------------------------------------|
| Local Only          | `'john'@'localhost'`        | Only from same machine                         |
| Specific IP         | `'john'@'192.168.1.100'`    | Only from a given IP                           |
| Any IP (wildcard)   | `'john'@'%'`                | From anywhere (be careful with this in prod!)  |
| Hostname-based      | `'john'@'host.example.com'` | Only from a named computer                     |

**Tip:** Use `'%'` only if you really need remote access.

### SQL Examples

-- Local user (only from the server itself)
CREATE USER 'localuser'@'localhost' IDENTIFIED BY 'password1';

-- Remote user, any IP
CREATE USER 'remoteuser'@'%' IDENTIFIED BY 'password2';

-- Remote user, specific IP
CREATE USER 'user_ip'@'192.168.1.9' IDENTIFIED BY 'password3';

text

**Grant privileges:**

GRANT SELECT ON company_db.* TO 'remoteuser'@'%';
GRANT ALL PRIVILEGES ON company_db.* TO 'localuser'@'localhost';
REVOKE DELETE ON company_db.* FROM 'localuser'@'localhost';
FLUSH PRIVILEGES;

text

---

## 2. Secure Installation of MySQL on Ubuntu

Always **secure your server** after installation:

sudo mysql_secure_installation

text
- Sets a root password
- Removes test DB
- Removes anonymous users
- Disables remote root login

**Install MySQL server:**

sudo apt update
sudo apt upgrade -y
sudo apt install mysql-server -y

text

Check status:
sudo systemctl status mysql

text

---

## 3. Multi-Instance MySQL and Replication (Overview)

### Why multi-instance?
- Test replication on a single Ubuntu VM by running MySQL on different ports and folders.



**Key settings per instance:**
- Unique port (e.g., 3306, 3307)
- Unique datadir and socket path
- Unique `server-id`
- Separate [mysqld] config sections

### Basic Replication Setup Steps

1. **Configure master** (`server-id=1`, enable `log_bin`)
2. **Create replication user:**
    ```
    CREATE USER 'repl'@'%' IDENTIFIED BY 'password';
    GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
    FLUSH PRIVILEGES;
    ```
3. **On master:**
    ```
    SHOW MASTER STATUS;
    ```
   Note file and position
4. **On slave:**  
   - Set `server-id=2`, `relay_log`, etc. in config
   - Start replication using CHANGE MASTER TO...

#### For modern GTID-based replication:
- Add
    ```
    gtid_mode=ON
    enforce_gtid_consistency=ON
    log_slave_updates=ON
    binlog_format=ROW
    ```
- Use  
    ```
    CHANGE MASTER TO MASTER_AUTO_POSITION=1;
    START SLAVE;
    ```

---

## 4. Percona Monitoring and Management (PMM)

**PMM** is a free toolkit that gives you dashboards and query analytics for MySQL.

### Phase 1: Prepare Ubuntu and Install Docker

sudo apt update
sudo apt upgrade -y

sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

Optional
sudo usermod -aG docker $USER
newgrp docker

text

Test Docker with:
docker run hello-world

text

### Phase 2: Install PMM Agent (Client)

cd /tmp
wget https://downloads.percona.com/downloads/pmm3/3.2.0/binary/debian/noble/amd64/pmm-client_3.2.0-7.noble_amd64.deb
sudo dpkg -i pmm-client_3.2.0-7.noble_amd64.deb

which pmm-agent
pmm-agent --version

text

### Phase 3: Run PMM Server (Docker)

docker run -d
-p 8080:80
-p 443:8443
--name pmm-server
percona/pmm-server:latest

text

Open PMM dashboard at  
`http://<YOUR_UBUNTU_IP>:8080`  
(default: `admin` / `admin` – change the password!)

### Phase 4: Setup PMM Agent

sudo pmm-agent setup
--config-file=/etc/pmm-agent.yaml
--server-address=YOUR_PMM_SERVER_IP:443
--server-insecure-tls
--server-username=admin
--server-password=YOUR_PASSWORD
--force

text

### Phase 5: Register MySQL Instances for Monitoring

#### On master (port 3306):

CREATE USER 'pmm'@'localhost' IDENTIFIED BY 'pmm_password_master';
GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, EVENT, RELOAD ON . TO 'pmm'@'localhost';
FLUSH PRIVILEGES;

text
#### On slave (port 3307):

CREATE USER 'pmm2'@'localhost' IDENTIFIED BY 'pmm_password_slave';
GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, EVENT, RELOAD ON . TO 'pmm2'@'localhost';
FLUSH PRIVILEGES;

text

#### Register MySQL with PMM:

sudo pmm-admin add mysql
--query-source=perfschema
--username=pmm
--password='pmm_password_master'
--host=127.0.0.1
--port=3306
--service-name=mysql-master

sudo pmm-admin add mysql
--query-source=perfschema
--username=pmm2
--password='pmm_password_slave'
--host=127.0.0.1
--port=3307
--service-name=mysql-slave

text

Check with:
sudo pmm-admin list

text
Your PMM dashboards should now show both MySQL instances!

---

## 5. Typical Next Steps & Add-ons

- Set up **cron jobs** for automated backup and health check scripts
- Write Bash scripts for auto backup, backup rotation, and crash simulation
- Practice troubleshooting with **SHOW SLAVE STATUS**, `RESET SLAVE ALL`, and exploring slow queries in PMM
- Run and analyze sample `EXPLAIN` plans for performance

---

## Why Use This Lab as a Freelancer or DBA?

- **Shows practical, production-like MySQL setup (multi-instance, replication, full observability)**
- **Documents clear, repeatable steps for real-world deployments**
- **Demonstrates readiness for advanced tasks (automation, monitoring, DR)**
- **Perfect project to share with potential clients or employers!**

---

**Copy, adapt, and learn—this lab is your launchpad for MySQL automation and modern DBA work!**