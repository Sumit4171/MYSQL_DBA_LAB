# MySQL Database, Table, and User Management Script – Friendly Explanation

This guide walks you through each part of a typical MySQL database setup, user management, and basic permissions workflow – **step by step, with simple explanations and examples**.

---

## 1. Create and Select a Database

CREATE DATABASE company_db;
USE company_db;


**What this does:**  
- `CREATE DATABASE company_db;` makes a new "company_db" database to hold your company's data.
- `USE company_db;` tells MySQL to work in that database from now on.

---

## 2. Create Tables for Employees and Departments

-- Employees table
CREATE TABLE employees (
emp_id INT PRIMARY KEY AUTO_INCREMENT,
name VARCHAR(100),
department VARCHAR(50),
salary DECIMAL(10,2)
);

-- Departments table
CREATE TABLE departments (
dept_id INT PRIMARY KEY AUTO_INCREMENT,
dept_name VARCHAR(100),
location VARCHAR(100)
);


**What this does:**  
- `employees` table stores staff info (auto-generated IDs, names, department name, and salary).
- `departments` table keeps track of department names and locations.

**Example:**
- An employee named Alice in HR with salary 50,000 will be one row in `employees`.
- The HR department in Delhi will be one row in `departments`.

---

## 3. Insert Example Data

INSERT INTO employees (name, department, salary) VALUES
('Alice', 'HR', 50000),
('Bob', 'Finance', 60000),
('Charlie', 'IT', 70000);

INSERT INTO departments (dept_name, location) VALUES
('HR', 'Delhi'),
('Finance', 'Mumbai'),
('IT', 'Bangalore');


**What this does:**  
- Adds three employees and three departments to your database.

---

## 4. MySQL User Management and Permissions

### Types of Users – by Where They Can Connect From

-- Local only (from same server)
CREATE USER 'user_local'@'localhost' IDENTIFIED BY 'local123';

-- Remote, from anywhere
CREATE USER 'user_remote'@'%' IDENTIFIED BY 'remote123';

-- From one specific IP
CREATE USER 'user_ip'@'192.168.1.9' IDENTIFIED BY 'ipuser123';


- `'user_local'@'localhost'`: Only works if they connect from the server itself.
- `'user_remote'@'%'`: Can connect from any IP address.
- `'user_ip'@'192.168.1.9'`: Only from your home/office IP.

---

### Granting Privileges

-- 1. Give 'user_remote' read-only access
GRANT SELECT ON company_db.* TO 'user_remote'@'%';

-- 2. Give 'user_ip' full access to everything in company_db
GRANT SELECT, INSERT, UPDATE, DELETE ON company_db.* TO 'user_ip'@'192.168.1.9';
FLUSH PRIVILEGES;

-- 3. Give 'user_local' all rights
GRANT ALL PRIVILEGES ON company_db.* TO 'user_local'@'localhost';
FLUSH PRIVILEGES;


- `GRANT ...`: Gives users permission to read, edit, or manage data.
- `FLUSH PRIVILEGES;`: Makes the permission changes take effect.

---

### Checking and Removing Permissions or Users

-- See what 'user_remote' is allowed to do
SHOW GRANTS FOR 'user_remote'@'%';

-- See what 'user_ip' can do
SHOW GRANTS FOR 'user_ip'@'192.168.1.9';

-- Remove/deactivate a user from MySQL
DROP USER 'user_ip'@'192.168.1.9';

-- See all MySQL users and where they can connect from
SELECT user, host FROM mysql.user;



---

### Revoke (Remove) a Single Permission

-- Take away DELETE rights from 'user_local'
REVOKE DELETE ON company_db.* FROM 'user_local'@'localhost';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'user_local'@'localhost';



---

## 5. Logging In and Practicing

### Log In to MySQL as New User

If you are on your Ubuntu server:
mysql -u user_local -p


(Enter `local123` as password when prompted.)

### Use Your Database
USE company_db;


---

## 6. Safe Tests: Transactions

Test changes without making them permanent:
START TRANSACTION;
DELETE FROM employees WHERE emp_id = 1;
ROLLBACK;


- Delete Alice (emp_id 1), but `ROLLBACK` undoes it, so no data is lost.

---

## 7. Using Roles for Easy Privilege Management

Roles let you grant a "batch of permissions" to many users.

-- Create a role
CREATE ROLE 'read_only';

-- Make a user
CREATE USER 'user_role'@'%' IDENTIFIED BY 'role123';
FLUSH PRIVILEGES;

-- Grant SELECT permission to role
GRANT SELECT ON company_db.* TO 'read_only';
GRANT USAGE ON . TO 'read_only';
FLUSH PRIVILEGES;

-- Assign role to user
GRANT 'read_only' TO 'user_role'@'%';
SET DEFAULT ROLE 'read_only' TO 'user_role'@'%';



**What this does:**  
- The user `user_role` now has read-only access, not edit rights.

---

### Check and Test Role Permissions

SHOW GRANTS FOR 'user_role'@'%';

-- Try to insert (will fail if user only has read rights)
START TRANSACTION;
INSERT INTO employees (name, department, salary) VALUES ('Test User', 'HR', 50000.00);


---

## **Summary Table**

| Task                      | What the SQL Does                                                                   |
|---------------------------|-------------------------------------------------------------------------------------|
| Create DB, Table          | Prepares storage for your company's employees and departments                       |
| Insert Data               | Adds sample employees and departments                                               |
| Create User               | Makes login accounts with different remote/local access                             |
| Grant Privileges          | Controls who can view or change what data                                           |
| Remove/Revoke Privileges  | Removes some or all powers from a user                                              |
| Roles                     | Batch permissions: assign the same rights to many people easily                     |
| Safe Testing              | Test big changes with `START TRANSACTION` / `ROLLBACK` before making them permanent |

---

### **Why use this script?**

- Great for beginners learning real-world MySQL management
- Lets you safely practice users, permissions, table creation, and roles
- Shows what real companies do to set up secure, organized access to their databases
