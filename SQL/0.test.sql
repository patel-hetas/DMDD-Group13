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
EXEC sp_createUser_customer 'customer1', 'Customer 1', 'password', '1234567890', @user_id OUTPUT;
GO

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
EXEC sp_createUser_customer 'customer2', 'Customer 2', 'password', '1234567890', @user_id OUTPUT;
GO

DECLARE @user_id INT;
DECLARE @answersToManagerID INT;
EXEC sp_createUser_customer 'customer3', 'Customer 3', 'password', '1234567890', @user_id OUTPUT;
GO

-- 1.4 Modify a user

DECLARE @user_id INT;
DECLARE @password_not_encrypted VARCHAR(50);
SET @user_id = (SELECT id FROM users WHERE username = 'customer3');
SET @password_not_encrypted = 'password';
EXEC sp_modifyUserByUserID @user_id, 'customer3', 'Customer 3', @password_not_encrypted, '1145141919810';

--- 1.4 Login Test
EXEC sp_loginUser 'manager1', 'password';
EXEC sp_loginUser 'clerk1', 'password';
EXEC sp_loginUser 'clerk2', 'password';
EXEC sp_loginUser 'customer1', 'password';
EXEC sp_loginUser 'customer2', 'password';
EXEC sp_loginUser 'customer3', 'password';
EXEC sp_loginUser 'wrong_username', 'wrong_password';

SELECT * FROM users;

