-- SP for login start
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
-- SP for login end

-- SP for updating user information start
DROP PROCEDURE IF EXISTS sp_modifyUserByUserID;
GO
CREATE PROCEDURE sp_modifyUserByUserID
    @user_id INT,
    @username VARCHAR(50),
    @displayName VARCHAR(50),
    @password_not_encrypted VARCHAR(50),
    @phone VARCHAR(15)
AS
BEGIN
    OPEN SYMMETRIC KEY UserPasswordKey DECRYPTION BY CERTIFICATE UserPasswordCertificate;
    UPDATE users
    SET username = @username, displayName = @displayName, password_encrypted = dbo.fn_getEncryptedPassword(@password_not_encrypted), phone = @phone
    WHERE id = @user_id;
END;
GO
-- SP for updating user information end     


-- SP for cancelling a ticket start
DROP PROCEDURE IF EXISTS sp_cancelTicket;
GO
CREATE PROCEDURE sp_cancelTicket -- Cancel Ticket
    @ticket_id INT
AS
BEGIN
    DECLARE @payment_id INT;
    SELECT @payment_id = payment_id
    FROM tickets
    WHERE ticket_id = @ticket_id;

    UPDATE tickets
    SET ticket_status = 'Cancelled', payment_id = NULL
    WHERE ticket_id = @ticket_id;

    DECLARE @current_amount FLOAT;
    SELECT @current_amount = amount
    FROM transactions
    WHERE payment_id = @payment_id;

    DECLARE @new_amount FLOAT;
    SELECT @new_amount = @current_amount - (SELECT price FROM schedules WHERE schedule_id = (SELECT schedule_id FROM tickets WHERE ticket_id = @ticket_id))

    IF @new_amount <= 0
    BEGIN
        DELETE FROM transactions
        WHERE payment_id = @payment_id;
    END
    ELSE
    BEGIN
        UPDATE transactions
        SET amount = @new_amount
        WHERE payment_id = @payment_id;
    END
END;
GO
-- SP for cancelling a ticket start

-- =========================================================================================================
-- Procedure to check ticket availability
DROP PROCEDURE IF EXISTS CheckTicketAvailability
GO
CREATE PROCEDURE CheckTicketAvailability
    @seatId INT,
    @scheduleId INT,
    @ticketId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the ticket is available for the seat and schedule
    SELECT @ticketId = ticket_id
    FROM tickets
    WHERE seat_id = @seatId AND schedule_id = @scheduleId AND ticket_status = 'Available';
END;
GO

DROP PROCEDURE IF EXISTS sp_createStudio;
GO
CREATE PROCEDURE sp_createStudio -- Create Studio
    @name VARCHAR(50),
    @screen_type VARCHAR(10),
    @studio_id INT OUTPUT
AS
BEGIN
    INSERT INTO studios (studio_name, screen_type)
    VALUES (@name, @screen_type);

    SET @studio_id = SCOPE_IDENTITY();
END;
GO


-- Procedure to create a new transaction
DROP PROCEDURE IF EXISTS CreateTransaction
GO
CREATE PROCEDURE CreateTransaction
    @userId INT,
    @price FLOAT,
    @paymentMethod VARCHAR(50),
    @paymentId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert a new transaction with 'Pending' status
    INSERT INTO transactions (user_id, amount, payment_method)
    VALUES (@userId, @price, @paymentMethod); -- replace @paymentMethod with the actual payment method if known

    -- Retrieve the new transaction ID
    SELECT @paymentId = SCOPE_IDENTITY();
END;
GO

-- Procedure to update ticket status and link to transaction
DROP PROCEDURE IF EXISTS UpdateTicketAndTransaction
GO
CREATE PROCEDURE UpdateTicketAndTransaction
    @ticketId INT,
    @userId INT,
    @paymentId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the ticket status and link to the transaction
    UPDATE tickets
    SET user_id = @userId, ticket_status = 'Payment Pending', payment_id = @paymentId
    WHERE ticket_id = @ticketId;
END;
GO

-- Main procedure to book ticket
DROP PROCEDURE IF EXISTS sp_BookTicket
GO
CREATE PROCEDURE sp_BookTicket
    @userId INT,
    @seatId INT,
    @scheduleId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Ensures that the transaction is rolled back on error

    -- Variable to hold the price and new payment ID
    DECLARE @price FLOAT;
    DECLARE @paymentId INT;
    DECLARE @ticketId INT;

    -- Start the transaction
    BEGIN TRAN;

    -- Check ticket availability
    EXEC CheckTicketAvailability @seatId, @scheduleId, @ticketId OUTPUT;

    IF @ticketId IS NULL
    BEGIN
        -- If no ticket is available, exit the procedure
        RAISERROR('The selected seat is not available for this schedule.', 16, 1);
        RETURN;
    END;

    -- Get the price for the schedule
    SELECT @price = price
    FROM schedules
    WHERE schedule_id = @scheduleId;

    -- Create a new transaction
    EXEC CreateTransaction @userId, @price, 'Credit Card', @paymentId OUTPUT; -- replace 'Credit Card' with the actual payment method if known

    -- Update ticket status and link to transaction
    EXEC UpdateTicketAndTransaction @ticketId, @userId, @paymentId;

    -- If everything is successful, commit the transaction
    COMMIT TRAN;

    SELECT 'Ticket successfully booked with payment pending.' AS Message, @ticketId AS TicketId, @paymentId AS PaymentId;
END;
GO
-- =========================================================================================================

-- SP to associate a genre with a movie
DROP PROCEDURE IF EXISTS sp_associateGenreWithMovie;
GO
CREATE PROCEDURE sp_associateGenreWithMovie -- Associate Genre with Movie
    @movie_id INT,
    @genre_id INT
AS
BEGIN
    INSERT INTO movies_genres (movie_id, genre_id)
    VALUES (@movie_id, @genre_id);
END;
GO