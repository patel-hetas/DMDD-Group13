USE ttms;
GO

--- 0. About Encryption
DROP FUNCTION IF EXISTS fn_getEncryptedPassword;
GO
CREATE FUNCTION fn_getEncryptedPassword -- Get Encrypted Password
    (@password_not_encrypted VARCHAR(50))
RETURNS VARBINARY
AS
BEGIN
    DECLARE @password_encrypted VARBINARY;
    SET @password_encrypted = ENCRYPTBYKEY(KEY_GUID('UserPasswordKey'), @password_not_encrypted);
    RETURN @password_encrypted;
END;
GO

DROP FUNCTION IF EXISTS fn_getDecryptedPassword;
GO
CREATE FUNCTION fn_getDecryptedPassword -- Get Decrypted Password
    (@password_encrypted VARBINARY)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @password_not_encrypted VARCHAR(50);
    SET @password_not_encrypted = DECRYPTBYKEY(@password_encrypted);
    RETURN @password_not_encrypted;
END;
GO

--- 1. About Users
--- 1.1. Create User
DROP PROCEDURE IF EXISTS sp_createUser; 
GO
CREATE PROCEDURE sp_createUser -- Create User with given role
    @username VARCHAR(50),
    @displayName VARCHAR(50),
    @password_not_encrypted VARCHAR(50),
    @phone VARCHAR(15),
    @role VARCHAR(25),
    @user_id INT OUTPUT
AS
BEGIN
    --- Check if the user already exists
    IF EXISTS (SELECT * FROM users WHERE username = @username)
    BEGIN
        RAISERROR('User already exists', 16, 1);
        RETURN;
    END

    DECLARE @password_encrypted VARBINARY;
    OPEN SYMMETRIC KEY UserPasswordKey DECRYPTION BY CERTIFICATE UserPasswordCertificate;
    SET @password_encrypted = dbo.fn_getEncryptedPassword(@password_not_encrypted);

    INSERT INTO users (username, displayName, password_encrypted, phone, [role])
    VALUES (@username, @displayName, @password_encrypted, @phone, @role);

    SET @user_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_createUser_manager;
GO
CREATE PROCEDURE sp_createUser_manager -- Create Manager
    @username VARCHAR(50),
    @displayName VARCHAR(50),
    @password_not_encrypted VARCHAR(50),
    @phone VARCHAR(15),
    @salary FLOAT,
    @dateOfEmployment DATE,
    @user_id INT OUTPUT
AS
BEGIN
    DECLARE @role VARCHAR(25);
    SET @role = 'Manager';
    EXEC sp_createUser @username, @displayName, @password_not_encrypted, @phone, @role, @user_id=@user_id OUTPUT;
    INSERT INTO users_managers (manager_id, salary, dateOfEmployment)
    VALUES (@user_id, @salary, @dateOfEmployment);
END;
GO

DROP PROCEDURE IF EXISTS sp_createUser_clerk;
GO
CREATE PROCEDURE sp_createUser_clerk -- Create Clerk
    @username VARCHAR(50),
    @displayName VARCHAR(50),
    @password_not_encrypted VARCHAR(50),
    @phone VARCHAR(15),
    @salary FLOAT,
    @dateOfEmployment DATE,
    @answersToManagerID INT,
    @user_id INT OUTPUT
AS
BEGIN
    DECLARE @role VARCHAR(25);
    SET @role = 'Clerk';
    EXEC sp_createUser @username, @displayName, @password_not_encrypted, @phone, @role, @user_id = @user_id OUTPUT;
    INSERT INTO users_clerks (customer_id, dateOfEmployment, salary, answersToManagerID)
    VALUES (@user_id, @dateOfEmployment, @salary, @answersToManagerID);
END;
GO

DROP PROCEDURE IF EXISTS sp_createUser_customer;
GO
CREATE PROCEDURE sp_createUser_customer -- Create Customer
    @username VARCHAR(50),
    @displayName VARCHAR(50),
    @password_not_encrypted VARCHAR(50),
    @phone VARCHAR(15),
    @customer_id INT OUTPUT
AS
BEGIN
    DECLARE @role VARCHAR(25);
    SET @role = 'Customer';
    EXEC sp_createUser @username, @displayName, @password_not_encrypted, @phone, @role, @user_id = @customer_id OUTPUT;
    INSERT INTO users_customers (customer_id)
    VALUES (@customer_id);
    
END;
GO

--- 1.2 Login User
DROP PROCEDURE IF EXISTS sp_loginUser;
GO
CREATE PROCEDURE sp_loginUser -- Login User
    @username VARCHAR(50),
    @password_not_encrypted VARCHAR(50)
AS
BEGIN
    DECLARE @password_encrypted VARBINARY;
    DECLARE @user_id INT;
    DECLARE @role VARCHAR(25);

    OPEN SYMMETRIC KEY UserPasswordKey DECRYPTION BY CERTIFICATE UserPasswordCertificate;
    SET @password_encrypted = ENCRYPTBYKEY(KEY_GUID('UserPasswordKey'), @password_not_encrypted);

    SELECT @user_id = id, @role = [role]
    FROM users
    WHERE username = @username AND password_encrypted = @password_encrypted;

    IF @user_id IS NULL
    BEGIN
        RAISERROR('Invalid username or password', 16, 1);
        RETURN;
    END

    SELECT @user_id AS user_id, @role AS role;
END;
GO

USE master;
GO