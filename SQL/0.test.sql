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

--- 3.1 About Seats
-- test for seats
ALTER TABLE seats
ADD SeatLabel AS dbo.GetSeatLabel(seat_row, seat_column);
GO

--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO studios (studio_name, screen_type) VALUES ('My Studio', '2D');
INSERT INTO seats (studio_id, seat_row, seat_column) 
VALUES (1, 5, 10); 

select * from seats;

-- 4. About Transactions
--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO transactions (user_id, amount, payment_method) 
VALUES (1, 150.00, 'Credit Card');

-- test for transactions
ALTER Table transactions
ADD TotalAmountWithServiceCharge AS dbo.GetTotalAmount(amount);

select * from transactions;

--- 5. About Schedules and Tickets
--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO movies (movie_name, duration, age_rating)
VALUES ('Your Movie Name', 120, 'PG-13');

INSERT INTO schedules (movie_id, studio_id, start_time, end_time, price)
VALUES (1, 1, '2024-01-01T09:00:00', '2024-01-01T11:15:00', 10.00);
select * from schedules;

-- test for schedules
DECLARE @TestStartTime DATETIME = '2024-01-01T09:00:00';
DECLARE @TestEndTime DATETIME = '2024-01-01T11:15:00';
SELECT dbo.GetScheduleDuration(@TestStartTime, @TestEndTime) AS DurationTestResult;

--- 5.1 About Tickets
select * from tickets;

--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status, payment_id) 
VALUES (2, 3, 1, 'Booked', 1);

-- test for tickets
SELECT ticket_status,dbo.GetTicketStatusMessage(ticket_status) AS StatusMessage
FROM tickets;

--- 6. About Customer's Special Functionalities

--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO users_customers (customer_id, isVIP, dateOfMembership)
VALUES
(1, 1, '2024-01-01');

--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO movies (movie_name, duration, age_rating)
VALUES
('Movie Title 1', 120, 'PG');

select * from movies;

--just for testing purpose, if we have insert queries already, then no need for these extra insert queries
INSERT INTO customer_MovieReviews (customer_id, movie_id, rating, comment, dateAndTime)
VALUES
(1, 1, 5, 'Great movie with excellent storytelling!', '2024-04-06 20:00:00');

-- test for customer movie reviews
ALTER TABLE customer_MovieReviews
ADD review_category AS dbo.GetReviewCategory(rating);

select * from customer_MovieReviews;

--- 7. About Manager's Special Functionalities

INSERT INTO events (event_name, event_description, event_start_time, event_end_time, studio_id, event_revenue, manager_id)
VALUES ('Event Name 1', 'Description of Event 1', '2024-04-10 10:00:00', '2024-04-10 14:00:00', 1, 10000.00, 1);

SELECT event_id, event_name, dbo.CalculateRevenuePerHour(event_revenue, event_start_time, event_end_time) AS revenue_per_hour
FROM events;