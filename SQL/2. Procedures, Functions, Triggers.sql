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

--- 1.3. Modify User Information
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
    UPDATE users
    SET username = @username, displayName = @displayName, password_encrypted = dbo.fn_getEncryptedPassword(@password_not_encrypted), phone = @phone
    WHERE id = @user_id;
END;
GO


--- 2. About Movies

--- 2.1 Movie Itself
DROP PROCEDURE IF EXISTS sp_createMovie;
GO
CREATE PROCEDURE sp_createMovie -- Create Movie
    @name VARCHAR(50),
    @duration INT,
    @age_rating VARCHAR(10),
    @movie_id INT OUTPUT
AS
BEGIN
    INSERT INTO movies (movie_name, duration, age_rating)
    VALUES (@name, @duration, @age_rating);

    SET @movie_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyMovie;
GO
CREATE PROCEDURE sp_modifyMovie
    @movie_id INT,
    @name VARCHAR(50),
    @duration INT,
    @age_rating VARCHAR(10)
AS
BEGIN
    UPDATE movies
    SET movie_name = @name, duration = @duration, age_rating = @age_rating
    WHERE movie_id = @movie_id;
END;
GO

--- 2.2 Actors

DROP PROCEDURE IF EXISTS sp_createActor;
GO
CREATE PROCEDURE sp_createActor -- Create Actor
    @name VARCHAR(50),
    @bio TEXT,
    @actor_id INT OUTPUT
AS
BEGIN
    INSERT INTO actors (actor_name, bio)
    VALUES (@name, @bio);

    SET @actor_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyActor;
GO
CREATE PROCEDURE sp_modifyActor -- Modify Actor
    @actor_id INT,
    @name VARCHAR(50),
    @bio TEXT
AS
BEGIN
    UPDATE actors
    SET actor_name = @name, bio = @bio
    WHERE actor_id = @actor_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_associateActorWithMovie;
GO
CREATE PROCEDURE sp_associateActorWithMovie -- Associate Actor with Movie
    @movie_id INT,
    @actor_id INT
AS
BEGIN
    INSERT INTO movies_actors (movie_id, actor_id)
    VALUES (@movie_id, @actor_id);
END;
GO

DROP PROCEDURE IF EXISTS sp_disassociateActorWithMovie;
GO
CREATE PROCEDURE sp_disassociateActorWithMovie -- Disassociate Actor with Movie
    @movie_id INT,
    @actor_id INT
AS
BEGIN
    DELETE FROM movies_actors
    WHERE movie_id = @movie_id AND actor_id = @actor_id;
END;
GO

--- 2.3 Genres

DROP PROCEDURE IF EXISTS sp_createGenre;
GO
CREATE PROCEDURE sp_createGenre -- Create Genre
    @name VARCHAR(50),
    @genre_id INT OUTPUT
AS
BEGIN
    INSERT INTO genres (genre_name)
    VALUES (@name);

    SET @genre_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyGenre;
GO
CREATE PROCEDURE sp_modifyGenre -- Modify Genre
    @genre_id INT,
    @name VARCHAR(50)
AS
BEGIN
    UPDATE genres
    SET genre_name = @name
    WHERE genre_id = @genre_id;
END;
GO

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

DROP PROCEDURE IF EXISTS sp_disassociateGenreWithMovie;
GO
CREATE PROCEDURE sp_disassociateGenreWithMovie -- Disassociate Genre with Movie
    @movie_id INT,
    @genre_id INT
AS
BEGIN
    DELETE FROM movies_genres
    WHERE movie_id = @movie_id AND genre_id = @genre_id;
END;
GO

USE master;
GO




-- Stored Procedure to add a New Movie
DROP PROCEDURE IF EXISTS sp_BookTicket;
GO
CREATE PROCEDURE sp_BookTicket
    @schedule_id INT,
    @seat_id INT,
    @user_id INT,
    @payment_method VARCHAR(255),
    @amount FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert transaction first
    DECLARE @payment_id INT;
    INSERT INTO transactions (user_id, amount, payment_method)
    VALUES (@user_id, @amount, @payment_method);

    SET @payment_id = SCOPE_IDENTITY();

    -- Insert ticket with status 'Booked' and link the transaction
    INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status, payment_id)
    VALUES (@schedule_id, @seat_id, @user_id, 'Booked', @payment_id);
END;
GO



-- Record Event Revenue
DROP PROCEDURE IF EXISTS sp_RecordEventRevenue;
GO
CREATE PROCEDURE sp_RecordEventRevenue
    @event_id INT,
    @revenue FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    -- Update the event's revenue
    UPDATE events
    SET event_revenue = @revenue
    WHERE event_id = @event_id;
END;
GO


-- Add a Movie Review
DROP PROCEDURE IF EXISTS sp_AddMovieReview;
GO
CREATE PROCEDURE sp_AddMovieReview
    @customer_id INT,
    @movie_id INT,
    @rating INT,
    @comment TEXT,
    @dateAndTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate the rating value
    IF NOT (@rating BETWEEN 1 AND 5)
        THROW 50002, 'Rating must be between 1 and 5.', 1;

    INSERT INTO customer_MovieReviews (customer_id, movie_id, rating, comment, dateAndTime)
    VALUES (@customer_id, @movie_id, @rating, @comment, @dateAndTime);
END;
GO



-- ================================================Triggers==================================================

-- Generate Tickets Once a Movie Schedule is Released
DROP TRIGGER IF EXISTS trg_GenerateTicketsOnNewSchedule;
GO
CREATE TRIGGER trg_GenerateTicketsOnNewSchedule
ON schedules
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- For each new schedule, insert a new ticket for each seat in the studio
    INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status)
    SELECT 
        i.schedule_id, 
        s.seat_id, 
        NULL, 
        'Available'
    FROM 
        inserted i
        CROSS JOIN seats s
    WHERE 
        s.studio_id = i.studio_id;
END;
GO


-- Invalidate Tickets Upon Movie Schedule Cancellation
DROP TRIGGER IF EXISTS trg_InvalidateTicketsOnScheduleCancellation;
GO
CREATE TRIGGER trg_InvalidateTicketsOnScheduleCancellation
ON schedules
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(end_time)
    BEGIN
        DECLARE @schedule_id INT;

        SELECT @schedule_id = schedule_id FROM inserted WHERE end_time < GETDATE();

        -- Set the ticket_status to 'Cancelled' for all tickets associated with the cancelled schedule.
        UPDATE tickets
        SET ticket_status = 'Cancelled'
        WHERE schedule_id = @schedule_id;
    END
END;
GO


-- Update Seat Availability When Ticket is Cancelled
DROP TRIGGER IF EXISTS trg_UpdateSeatAvailabilityOnTicketCancelled;
GO
CREATE TRIGGER trg_UpdateSeatAvailabilityOnTicketCancelled
ON tickets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(ticket_status)
    BEGIN
        -- Assuming there is an 'is_available' column in the 'seats' table.
        UPDATE seats
        SET is_available = 1
        WHERE seat_id IN (SELECT seat_id FROM inserted WHERE ticket_status = 'Cancelled');
    END
END;
GO


-- Update Seat Availability When Ticket is Cancelled
DROP TRIGGER IF EXISTS trg_UpdateSeatAvailabilityOnTicketCancelled;
GO
CREATE TRIGGER trg_UpdateCustomerFeedbackScore
ON customer_feedbacks
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Assuming there is a feedback_score column in the users_customers table
    UPDATE users_customers
    SET feedback_score = feedback_score + 1 -- Or use a more complex calculation
    WHERE customer_id IN (SELECT customer_id FROM inserted);
END;
GO

-- ===================================================UDFs===========================================
--- 3.1 About Seats

DROP FUNCTION IF EXISTS dbo.GetSeatLabel;
GO
CREATE FUNCTION dbo.GetSeatLabel
( @SeatRow INT, 
  @SeatColumn INT)
 RETURNS VARCHAR(15)
 AS
 BEGIN 
	RETURN 'Row ' + CAST(@SeatRow AS VARCHAR(5)) + ' Seat ' + CAST(@SeatColumn AS VARCHAR(5));
END;
GO

-- 4. About Transactions
DROP FUNCTION IF EXISTS dbo.GetTotalAmount;
GO
CREATE FUNCTION	dbo.GetTotalAmount (@Amount FLOAT)
RETURNS FLOAT
AS
BEGIN
	DECLARE @ServiceCharge FLOAT = 5.00;
	Return @Amount + @ServiceCharge;
END;
GO

--- 5. About Schedules Tickets
DROP FUNCTION IF EXISTS dbo.GetScheduleDuration;
GO
CREATE FUNCTION dbo.GetScheduleDuration (@StartTime DATETIME, @EndTime DATETIME)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @TotalMinutes INT = DATEDIFF(MINUTE, @StartTime, @EndTime);
	DECLARE @Hours INT = @TotalMinutes / 60;
	DECLARE @Minutes INT = @TotalMinutes % 60;
	RETURN CAST(@Hours AS VARCHAR(10)) + 'h ' + RIGHT('0' + CAST(@Minutes AS VARCHAR(2)), 2) + 'm';
END;
GO

--- 5.1 About Tickets
DROP FUNCTION IF EXISTS dbo.GetTicketStatusMessage;
GO
CREATE FUNCTION dbo.GetTicketStatusMessage (@TicketStatus VARCHAR(255))
RETURNS VARCHAR(255)
AS
BEGIN 
	IF @TicketStatus = 'Booked'
		RETURN 'Ticket booked successfully';
	IF @TicketStatus = 'Cancelled'
		RETURN 'Ticket cancelled successfully';
	IF @TicketStatus = 'Available'
		RETURN 'Ticket is available';
	RETURN 'Unknown status';
END;
GO

--- 6. About Customer's Special Functionalities

DROP FUNCTION IF EXISTS dbo.GetReviewCategory;
GO
CREATE FUNCTION dbo.GetReviewCategory(@rating INT)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @category VARCHAR(50)
	SELECT @category = CASE 
        WHEN @rating = 5 THEN 'Excellent'
        WHEN @rating = 4 THEN 'Good'
        WHEN @rating = 3 THEN 'Average'
        WHEN @rating = 2 THEN 'Poor'
        WHEN @rating = 1 THEN 'Bad'
    ELSE 'Invalid Rating'
    END
    RETURN @category
END;
GO

--- 7. About Manager's Special Functionalities

DROP FUNCTION IF EXISTS dbo.CalculateRevenuePerHour;
GO
CREATE FUNCTION dbo.CalculateRevenuePerHour ( @event_revenue FLOAT, @event_start_time DATETIME, @event_end_time DATETIME)
RETURNS FLOAT
AS
BEGIN
	DECLARE @duration FLOAT
	DECLARE @revenuePerHour FLOAT

	SET @duration = DATEDIFF(HOUR, @event_start_time, @event_end_time)
	IF @duration = 0
		SET @revenuePerHour = 0
	ELSE
		SET @revenuePerHour = @event_revenue / @duration

	RETURN @revenuePerHour
END
