DROP DATABASE IF EXISTS ttms;
CREATE DATABASE ttms;
USE ttms;
GO

--- 1. About Users

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL,
    password VARCHAR(50) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    role VARCHAR(255) NOT NULL CONSTRAINT role_ck CHECK (role IN ('Customer', 'Clerk', 'Manager'))
);

DROP TABLE IF EXISTS users_customers;
CREATE TABLE users_customers (
    customer_id INT PRIMARY KEY FOREIGN KEY (customer_id) REFERENCES users(id),
    isVIP BIT NOT NULL DEFAULT 0, -- 0: not VIP, 1: VIP
);

DROP TABLE IF EXISTS users_managers;
CREATE TABLE users_managers (
    manager_id INT PRIMARY KEY FOREIGN KEY (manager_id) REFERENCES users(id),
    dateOfEmployment DATE NOT NULL
);


DROP TABLE IF EXISTS users_clerks;
CREATE TABLE users_clerks (
    customer_id INT PRIMARY KEY FOREIGN KEY (customer_id) REFERENCES users(id),
    dateOfEmployment DATE NOT NULL,
    salary FLOAT NOT NULL,
    answersToManagerID INT FOREIGN KEY (answersToManagerID) REFERENCES users_managers(manager_id)
);


