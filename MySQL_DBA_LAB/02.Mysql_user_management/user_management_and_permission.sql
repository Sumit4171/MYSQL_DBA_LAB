-- Create a New Database
CREATE DATABASE company_db;
use company_db;

-- Create an eomployees  table
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    department VARCHAR(50),
    salary DECIMAL(10,2)
);

-- Create  a departments table
CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100),
    location VARCHAR(100)
);


--Insert into employees
INSERT INTO employees (name, department, salary) VALUES
('Alice', 'HR', 50000),
('Bob', 'Finance', 60000),
('Charlie', 'IT', 70000);

-- Insert into departments
INSERT INTO departments (dept_name, location) VALUES
('HR', 'Delhi'),
('Finance', 'Mumbai'),
('IT', 'Bangalore');


--created the company_db database and two tables (employees, departments), 
-- now let’s move on to User Management & Permissions.

--When accessing a MySQL server remotely, the method depends on how the user is defined:

-- Local user (from same server)
CREATE USER 'user_local'@'localhost' IDENTIFIED BY 'local123';

-- Remote user from any IP
CREATE USER 'user_remote'@'%' IDENTIFIED BY 'remote123';

-- Specific IP (replace with your actual IP if needed)
CREATE USER 'user_ip'@'192.168.1.9' IDENTIFIED BY 'ipuser123';


--GRANT Permissions
--Example 1: Give read access (SELECT) on company_db to user_remote
GRANT SELECT on company_db.* to 'user_remote'@'%';

--Example 2: Give full access to only employees table for user_ip
GRANT SELECT, INSERT, UPDATE, DELETE ON company_db.* TO 'user_ip'@'192.168.1.9';
FLUSH PRIVILEGES;

--Example 3: Give ALL privileges on the database to user_local
GRANT all privileges on company_db.* to 'user_local'@'localhost';
flush privileges;

show GRANTS for 'user_remote'@'%';

SHOW GRANTS FOR 'user_ip'@'192.168.1.9';


DROP USER 'user_ip'@'192.168.1.9';


SELECT user, host FROM mysql.user;


--Revoke DELETE Privilege Only
REVOKE DELETE ON company_db.* FROM 'user_local'@'localhost';
flush privileges;
SHOW GRANTS FOR 'user_local'@'localhost';

--Log in as user_local from ubuntu server
-- mysql -u user_local -p;

--Switch to company_db database
 USE company_db;


--safe test
START TRANSACTION;
DELETE FROM employees WHERE id = 1;
ROLLBACK;


--Create Role
CREATE ROLE 'read_only';

--create user for example
CREATE USER 'user_role'@'%' IDENTIFIED BY 'role123';
flush privileges;

--Grant Permissions to Role
GRANT SELECT ON company_db.* TO 'read_only';
GRANT USAGE ON *.* TO 'read_only';
flush privileges;



--Assign Role to User
GRANT 'read_only' to 'user_role'@'%';


-- If you skip this:
-- SET DEFAULT ROLE 'read_only' TO 'user_role'@'%';
-- Then user will login with NO active permissions!
set DEFAULT role 'read_only' to 'user_role'@'%';

--Check User Privileges
SHOW GRANTS FOR 'user_role'@'%';

--safe test for user_role , trying to insert row into table employees, 
--but it do not have permission to do so.
start TRANSACTION;
INSERT INTO employees (name, department, salary)
VALUES ('Alice Test', 'HR', 50000.00);
















