
 PMM Server and Agent Installation on Ubuntu with Docker

This guide helps you install Percona Monitoring and Management (PMM) server and agent on Ubuntu 24.04, using Docker for the server and native .deb for the client. It is written for beginners with clear explanations.

📘 Phase 1: Prepare Ubuntu Server (PMM Host)

✅ Step 1: Update System Packages

Keeping your system up-to-date ensures all security patches and latest package versions are installed.

sudo apt update
sudo apt upgrade -y

✅ Step 2: Install Docker

PMM server runs in a Docker container. Let’s install Docker using the official repo.

sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings

Import Docker GPG key and add its APT repository:

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

Add Docker repo:

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

Install Docker Engine and related tools:

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

✅ Step 3: Add Current User to Docker Group

To run Docker without sudo:

sudo usermod -aG docker $USER
newgrp docker  # Activate it immediately in current session

✅ Step 4: Verify Docker Installation

docker run hello-world

Expected output: Docker is installed and working.

✅ Step 5: Install PMM Agent (Client)

The PMM agent will monitor your MySQL servers and report metrics to PMM server.

cd /tmp
wget https://downloads.percona.com/downloads/pmm3/3.2.0/binary/debian/noble/amd64/pmm-client_3.2.0-7.noble_amd64.deb
sudo dpkg -i pmm-client_3.2.0-7.noble_amd64.deb

✅ Step 6: Verify PMM Agent Installation

which pmm-agent
pmm-agent --version

🚀 Phase 2: Deploy PMM Server using Docker

✅ Step 1: Start the PMM Server Container

Map host ports 8080 (HTTP) and 443 (HTTPS) for access:

docker run -d \
  -p 8080:80 \
  -p 443:8443 \
  --name pmm-server \
  percona/pmm-server:latest

Wait a few minutes and check container status:

docker ps

You should see pmm-server with STATUS: Up... (healthy).

✅ Step 2: Access PMM UI

In your browser:

http://<Ubuntu_IP>:8080

https://<Ubuntu_IP>:443

Default credentials:

Username: admin

Password: admin

🔐 Change password after login!

🔧 Configure PMM Agent and Connect to PMM Server

sudo pmm-agent setup \
  --config-file=/etc/pmm-agent.yaml \
  --server-address=192.168.217.131:443 \
  --server-insecure-tls \
  --server-username=admin \
  --server-password=Changeme123 \
  --force

Replace 192.168.217.131 with your actual PMM server IP.

✅ Check Agent Status

sudo systemctl status pmm-agent
sudo pmm-admin status

🧩 Add MySQL Instances for Monitoring

✅ 1. Master MySQL Instance (Port 3306)

Create PMM User in MySQL:

CREATE USER 'pmm'@'localhost' IDENTIFIED BY 'pmm_password_master';
GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, EVENT, RELOAD ON *.* TO 'pmm'@'localhost';
FLUSH PRIVILEGES;

📌 Why these privileges?

SELECT, PROCESS: For querying server status.

SUPER: Required for certain performance insights.

REPLICATION CLIENT: If replication involved.

EVENT, RELOAD: Needed for event and cache-related metrics.

✅ 2. Slave MySQL Instance (Port 3307 or other)

Connect via socket:

sudo mysql -u root --socket=/var/run/mysqld/mysqld_slave.sock

Create PMM User in Slave:

CREATE USER 'pmm2'@'localhost' IDENTIFIED BY 'pmm_password_slave';
GRANT SELECT, PROCESS, SUPER, REPLICATION CLIENT, EVENT, RELOAD ON *.* TO 'pmm2'@'localhost';
FLUSH PRIVILEGES;

Identify TCP Port:

SHOW VARIABLES LIKE 'port';

Example: 3307

✅ Add Instances to PMM Monitoring

Add Slave:

sudo pmm-admin add mysql \
  --query-source=perfschema \
  --username=pmm2 \
  --password='pmm_password_slave' \
  --host=127.0.0.1 \
  --port=3307 \
  --service-name=mysql-slave

Add Master:

sudo pmm-admin add mysql \
  --query-source=perfschema \
  --username=pmm \
  --password='pmm_password_master' \
  --host=127.0.0.1 \
  --port=3306 \
  --service-name=mysql-master

✅ Final Verification

sudo pmm-admin list

You should see entries for:

Node (Linux)

mysql-master

mysql-slave

Open https://<Ubuntu_IP>:443 and check the MySQL dashboards.

🛡️ Summary

You now have:

A running PMM Server in Docker

A PMM Agent connected

Master & Slave MySQL instances monitored

This setup gives you a full-stack MySQL observability solution!

✅ Tip: Always secure your PMM users with complex passwords and limit privileges to monitoring only.