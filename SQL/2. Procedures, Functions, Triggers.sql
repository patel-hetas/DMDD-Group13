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
    INSERT INTO users_clerks (clerk_id, dateOfEmployment, salary, answersToManagerID)
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


--- 3. About Studios and Seats

--- 3.1 About Studios

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

DROP PROCEDURE IF EXISTS sp_modifyStudio;
GO
CREATE PROCEDURE sp_modifyStudio -- Modify Studio
    @studio_id INT,
    @name VARCHAR(50),
    @screen_type VARCHAR(10)
AS
BEGIN
    UPDATE studios
    SET studio_name = @name, screen_type = @screen_type
    WHERE studio_id = @studio_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteStudio;
GO
CREATE PROCEDURE sp_deleteStudio -- Delete Studio
    @studio_id INT
AS
BEGIN
    DELETE FROM studios
    WHERE studio_id = @studio_id;
END;
GO

--- 3.2 About Seats

DROP PROCEDURE IF EXISTS sp_createSeat;
GO
CREATE PROCEDURE sp_createSeat -- Create Seat
    @studio_id INT,
    @row INT,
    @column INT,
    @seat_id INT OUTPUT
AS
BEGIN
    INSERT INTO seats (studio_id, seat_row, seat_column)
    VALUES (@studio_id, @row, @column);

    SET @seat_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modiftySeat;
GO
CREATE PROCEDURE sp_modiftySeat -- Modify Seat
    @seat_id INT,
    @row INT,
    @column INT
AS
BEGIN
    UPDATE seats
    SET seat_row = @row, seat_column = @column
    WHERE seat_id = @seat_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteSeat;
GO
CREATE PROCEDURE sp_deleteSeat -- Delete Seat
    @seat_id INT
AS
BEGIN
    DELETE FROM seats
    WHERE seat_id = @seat_id;
END;
GO

DROP TRIGGER IF EXISTS trg_deleteSeatWhenDeletingStudio;
GO
CREATE TRIGGER trg_deleteSeatWhenDeletingStudio
ON studios
AFTER DELETE
AS
BEGIN
    DELETE FROM seats
    WHERE studio_id IN (SELECT studio_id FROM deleted);
END;
GO


--- 4. About Schedule, Tickets, and Transactions

--- 4.1 About Schedules

DROP PROCEDURE IF EXISTS sp_createSchedule;
GO
CREATE PROCEDURE sp_createSchedule -- Create Schedule
    @movie_id INT,
    @studio_id INT,
    @start_time DATETIME,
    @end_time DATETIME,
    @price FLOAT,
    @schedule_id INT OUTPUT
AS
BEGIN
    INSERT INTO schedules (movie_id, studio_id, start_time, end_time, price)
    VALUES (@movie_id, @studio_id, @start_time, @end_time, @price);

    SET @schedule_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifySchedule;
GO
CREATE PROCEDURE sp_modifySchedule -- Modify Schedule
    @schedule_id INT,
    @movie_id INT,
    @studio_id INT,
    @start_time DATETIME,
    @end_time DATETIME,
    @price FLOAT
AS
BEGIN
    UPDATE schedules
    SET movie_id = @movie_id, studio_id = @studio_id, start_time = @start_time, end_time = @end_time, price = @price
    WHERE schedule_id = @schedule_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteSchedule;
GO
CREATE PROCEDURE sp_deleteSchedule -- Delete Schedule
    @schedule_id INT
AS
BEGIN
    DELETE FROM schedules
    WHERE schedule_id = @schedule_id;
END;
GO

--- 4.2 About Tickets

DROP PROCEDURE IF EXISTS sp_createTicket;
GO
CREATE PROCEDURE sp_createTicket -- Create Ticket
    @schedule_id INT,
    @seat_id INT,
    @user_id INT,
    @ticket_id INT OUTPUT
AS
BEGIN
    DECLARE @ticket_status VARCHAR(255);
    SET @ticket_status = 'Available';

    INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status)
    VALUES (@schedule_id, @seat_id, @user_id, @ticket_status);

    SET @ticket_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyTicket;
GO
CREATE PROCEDURE sp_modifyTicket -- Modify Ticket
    @ticket_id INT,
    @schedule_id INT,
    @seat_id INT,
    @user_id INT,
    @ticket_status VARCHAR(255),
    @payment_id INT
AS
BEGIN
    UPDATE tickets
    SET schedule_id = @schedule_id, seat_id = @seat_id, user_id = @user_id, ticket_status = @ticket_status, payment_id = @payment_id
    WHERE ticket_id = @ticket_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteTicket;
GO
CREATE PROCEDURE sp_deleteTicket -- Delete Ticket
    @ticket_id INT
AS
BEGIN
    DELETE FROM tickets
    WHERE ticket_id = @ticket_id;
END;
GO

-- Generate Tickets Once a Movie Schedule is Released
DROP TRIGGER IF EXISTS trg_createTicketWhenScheduleIsCreated;
GO
CREATE TRIGGER trg_createTicketWhenScheduleIsCreated
ON schedules
AFTER INSERT
AS
BEGIN
    DECLARE @schedule_id INT;
    DECLARE @studio_id INT;
    DECLARE @seat_id INT;
    DECLARE @user_id INT;
    DECLARE @ticket_id INT;

    SELECT @schedule_id = schedule_id, @studio_id = studio_id
    FROM inserted;

    INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status)
    SELECT @schedule_id, seat_id, NULL, 'Available'
    FROM seats
    WHERE studio_id = @studio_id;
END;
GO


DROP TRIGGER IF EXISTS trg_cancelTicketWhenScheduleIsDeleted;
GO
CREATE TRIGGER trg_cancelTicketWhenScheduleIsDeleted
ON schedules
AFTER DELETE
AS
BEGIN
    DECLARE @schedule_id INT;

    SELECT @schedule_id = schedule_id
    FROM deleted;

    UPDATE tickets
    SET ticket_status = 'Cancelled'
    WHERE schedule_id = @schedule_id;
END;
GO

--- 4.3 About Transactions

-- Create an empty transaction with no money yet
DROP PROCEDURE IF EXISTS sp_createTransaction;
GO
CREATE PROCEDURE sp_createTransaction -- Create Transaction
    @user_id INT,
    @payment_method VARCHAR(255),
    @payment_id INT OUTPUT
AS
BEGIN
    INSERT INTO transactions (user_id, payment_method)
    VALUES (@user_id, @payment_method);

    SET @payment_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyTransaction;
GO
CREATE PROCEDURE sp_modifyTransaction -- Modify Transaction
    @payment_id INT,
    @user_id INT,
    @amount FLOAT,
    @payment_method VARCHAR(255)
AS
BEGIN
    UPDATE transactions
    SET user_id = @user_id, amount = @amount, payment_method = @payment_method
    WHERE payment_id = @payment_id;
END;
GO


--- 4.4 About Booking Tickets (dealing with transactions and tickets)

DROP PROCEDURE IF EXISTS sp_associateTransactionWithTicket_alsoIncreaseTheAmount;
GO
CREATE PROCEDURE sp_associateTransactionWithTicket_alsoIncreaseTheAmount -- Associate Transaction with Ticket
    @ticket_id INT,
    @payment_id INT
AS
BEGIN
    DECLARE @amount FLOAT;
    SELECT @amount = price
    FROM schedules
    WHERE schedule_id = (SELECT schedule_id FROM tickets WHERE ticket_id = @ticket_id);

    UPDATE transactions
    SET amount = amount + @amount
    WHERE payment_id = @payment_id;

    UPDATE tickets
    SET payment_id = @payment_id
    WHERE ticket_id = @ticket_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_bookTicket;
GO
CREATE PROCEDURE sp_bookTicket -- Book Ticket
    @ticket_id INT,
    @payment_id INT,
    @user_id INT,
    @payment_method VARCHAR(255)
AS
BEGIN
    IF @payment_id IS NULL
    BEGIN
        EXEC sp_createTransaction @user_id, @payment_method, @payment_id=@payment_id OUTPUT;
    END
    
    EXEC sp_associateTransactionWithTicket_alsoIncreaseTheAmount @ticket_id, @payment_id;

    UPDATE tickets
    SET ticket_status = 'Booked', payment_id = @payment_id
    WHERE ticket_id = @ticket_id;
END;
GO

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

--- 5. About Customer's Movie Reviews

DROP PROCEDURE IF EXISTS sp_createReview;
GO
CREATE PROCEDURE sp_createReview -- Create Review
    @customer_id INT,
    @movie_id INT,
    @rating INT,
    @comment TEXT,
    @dateAndTime DATETIME
AS
BEGIN
    IF NOT (@rating BETWEEN 1 AND 5)
    BEGIN
        RAISERROR('Rating must be between 1 and 5', 16, 1);
        RETURN;
    END

    INSERT INTO customer_MovieReviews (customer_id, movie_id, rating, comment, dateAndTime)
    VALUES (@customer_id, @movie_id, @rating, @comment, @dateAndTime);
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyReview;
GO
CREATE PROCEDURE sp_modifyReview -- Modify Review
    @review_id INT,
    @customer_id INT,
    @movie_id INT,
    @rating INT,
    @comment TEXT,
    @dateAndTime DATETIME
AS
BEGIN
    IF NOT (@rating BETWEEN 1 AND 5)
    BEGIN
        RAISERROR('Rating must be between 1 and 5', 16, 1);
        RETURN;
    END

    UPDATE customer_MovieReviews
    SET customer_id = @customer_id, movie_id = @movie_id, rating = @rating, comment = @comment, dateAndTime = @dateAndTime
    WHERE id = @review_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteReview;
GO
CREATE PROCEDURE sp_deleteReview -- Delete Review
    @review_id INT
AS
BEGIN
    DELETE FROM customer_MovieReviews
    WHERE id = @review_id;
END;
GO

--- 6. About Customer's Feedback

DROP PROCEDURE IF EXISTS sp_createFeedback;
GO
CREATE PROCEDURE sp_createFeedback -- Create Feedback
    @customer_id INT,
    @comment VARCHAR(255),
    @dateAndTime DATETIME
AS
BEGIN
    INSERT INTO customer_feedbacks (customer_id, comment, dateAndTime)
    VALUES (@customer_id, @comment, @dateAndTime);
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyFeedback;
GO
CREATE PROCEDURE sp_modifyFeedback -- Modify Feedback
    @feedback_id INT,
    @customer_id INT,
    @comment VARCHAR(255),
    @dateAndTime DATETIME
AS
BEGIN
    UPDATE customer_feedbacks
    SET customer_id = @customer_id, comment = @comment, dateAndTime = @dateAndTime
    WHERE id = @feedback_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteFeedback;
GO
CREATE PROCEDURE sp_deleteFeedback -- Delete Feedback
    @feedback_id INT
AS
BEGIN
    DELETE FROM customer_feedbacks
    WHERE id = @feedback_id;
END;
GO

--- 7. About Manager's Special Functionalities

DROP PROCEDURE IF EXISTS sp_createEvent;
GO
CREATE PROCEDURE sp_createEvent -- Create Event
    @name VARCHAR(255),
    @description TEXT,
    @start_time DATETIME,
    @end_time DATETIME,
    @studio_id INT,
    @manager_id INT,
    @event_revenue FLOAT,
    @event_id INT OUTPUT
AS
BEGIN
    INSERT INTO events (event_name, event_description, event_start_time, event_end_time, studio_id, manager_id, event_revenue)
    VALUES (@name, @description, @start_time, @end_time, @studio_id, @manager_id, @event_revenue);

    SET @event_id = SCOPE_IDENTITY();
END;
GO

DROP PROCEDURE IF EXISTS sp_modifyEvent;
GO
CREATE PROCEDURE sp_modifyEvent -- Modify Event
    @event_id INT,
    @name VARCHAR(255),
    @description TEXT,
    @start_time DATETIME,
    @end_time DATETIME,
    @studio_id INT,
    @manager_id INT,
    @event_revenue FLOAT
AS
BEGIN
    UPDATE events
    SET event_name = @name, event_description = @description, event_start_time = @start_time, event_end_time = @end_time, studio_id = @studio_id, manager_id = @manager_id, event_revenue = @event_revenue
    WHERE event_id = @event_id;
END;
GO

DROP PROCEDURE IF EXISTS sp_deleteEvent;
GO
CREATE PROCEDURE sp_deleteEvent -- Delete Event
    @event_id INT
AS
BEGIN
    DELETE FROM events
    WHERE event_id = @event_id;
END;
GO


-- 8. Functionalities for Statistics

DROP FUNCTION IF EXISTS GetRevenueByMovieID;
GO
CREATE FUNCTION GetRevenueByMovieID
    (@movie_id INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @revenue FLOAT;

    SELECT @revenue = (s.price)
    FROM schedules s
    JOIN tickets t on s.schedule_id = t.schedule_id
    WHERE s.movie_id = @movie_id AND t.ticket_status = 'Booked';
    
    RETURN @revenue;
END;
GO


DROP FUNCTION IF EXISTS GetRevenueByClertID;
GO
CREATE FUNCTION GetRevenueByClertID
    (@clerk_id INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @revenue FLOAT;

    SELECT @revenue = SUM(s.price)
    FROM schedules s
    JOIN tickets t on s.schedule_id = t.schedule_id
    WHERE t.user_id = @clerk_id AND t.ticket_status = 'Booked';
    
    RETURN @revenue;
END;
GO

DROP FUNCTION IF EXISTS GetRevenueByGenreID;
GO
CREATE FUNCTION GetRevenueByGenreID
    (@genre_id INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @revenue FLOAT;

    SELECT @revenue = SUM(s.price)
    FROM schedules s
    JOIN tickets t on s.schedule_id = t.schedule_id
    JOIN movies_genres mg on s.movie_id = mg.movie_id
    WHERE mg.genre_id = @genre_id AND t.ticket_status = 'Booked';
    
    RETURN @revenue;
END;
GO

DROP FUNCTION IF EXISTS GetRevenueByActorID;
GO
CREATE FUNCTION GetRevenueByActorID
    (@actor_id INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @revenue FLOAT;

    SELECT @revenue = SUM(s.price)
    FROM schedules s
    JOIN tickets t on s.schedule_id = t.schedule_id
    JOIN movies_actors ma on s.movie_id = ma.movie_id
    WHERE ma.actor_id = @actor_id AND t.ticket_status = 'Booked';
    
    RETURN @revenue;
END;
GO

USE master;
GO