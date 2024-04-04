USE ttms;
GO

--- 1. Creating users

-- 1.1. Create a manager

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
EXEC sp_createUser_manager 'manager1', 'Manager 1', 'password', '1234567890', 10000, '2021-01-01', @user_id OUTPUT;
GO

-- 1.2. Create 2 clerks

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
SET @answersToManagerID = (SELECT id FROM users WHERE [role] = 'Manager');
EXEC sp_createUser_clerk 'clerk1', 'Clerk 1', 'password', '1234567890', 5000, '2021-01-01', @answersToManagerID, @user_id OUTPUT;
GO

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
SET @answersToManagerID = (SELECT id FROM users WHERE [role] = 'Manager');
EXEC sp_createUser_clerk 'clerk2', 'Clerk 2', 'password', '1234567890', 5000, '2021-01-01', @answersToManagerID, @user_id OUTPUT;
GO

-- 1.3. Create 3 customers

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
EXEC sp_createUser_customer 'customer', 'Customer', 'password', '1234567890', @user_id OUTPUT;
GO

USE master;
GO