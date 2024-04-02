USE master;
DROP DATABASE IF EXISTS ttms;
GO
CREATE DATABASE ttms;
GO
USE ttms;
GO

--- 0. About Encryption
IF EXISTS (
    SELECT name KeyName,
    symmetric_key_id KeyID,
    key_length KeyLength,
    algorithm_desc KeyAlgorithm
    FROM sys.symmetric_keys
)
BEGIN
    DROP SYMMETRIC KEY UserPasswordKey;
    DROP CERTIFICATE UserPasswordCertificate;
    DROP MASTER KEY;
END

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'v%c*S_%&1CLH%$Srr-FvQ6cCN~>hVh_Jp0VKaSnc7/lWeBz{V,[>IRNMj*]kPFMH';

 
CREATE CERTIFICATE UserPasswordCertificate
    WITH SUBJECT = 'User Passwords For TTMS';
GO

CREATE SYMMETRIC KEY UserPasswordKey
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE UserPasswordCertificate;
GO

--- 1. About Users

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY(1,1),
    username VARCHAR(50) NOT NULL UNIQUE,
    displayName VARCHAR(50) NOT NULL,
    password_encrypted VARBINARY NOT NULL,
    phone VARCHAR(15) NOT NULL,
    [role] VARCHAR(25) NOT NULL CONSTRAINT role_ck CHECK (role IN ('Customer', 'Clerk', 'Manager')),
    isActivated BIT NOT NULL DEFAULT 1 -- 0: not activated, 1: activated
);

DROP TABLE IF EXISTS users_customers;
CREATE TABLE users_customers (
    customer_id INT PRIMARY KEY FOREIGN KEY (customer_id) REFERENCES users(id),
    isVIP BIT NOT NULL DEFAULT 0, -- 0: not VIP, 1: VIP
    dateOfMembership DATE NOT NULL
);

DROP TABLE IF EXISTS users_managers;
CREATE TABLE users_managers (
    manager_id INT PRIMARY KEY FOREIGN KEY (manager_id) REFERENCES users(id),
    salary FLOAT NOT NULL,
    dateOfEmployment DATE NOT NULL
);


DROP TABLE IF EXISTS users_clerks;
CREATE TABLE users_clerks (
    customer_id INT PRIMARY KEY FOREIGN KEY (customer_id) REFERENCES users(id),
    dateOfEmployment DATE NOT NULL,
    salary FLOAT NOT NULL,
    answersToManagerID INT FOREIGN KEY (answersToManagerID) REFERENCES users_managers(manager_id)
);


--- 2. About Movies
DROP TABLE IF EXISTS movies;
CREATE TABLE movies (
    movie_id INT PRIMARY KEY IDENTITY(1,1),
    movie_name VARCHAR(255) NOT NULL,
    duration INT NOT NULL, -- in minutes
    age_rating VARCHAR(10) NOT NULL CONSTRAINT age_rating_ck CHECK (age_rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17'))
);

--- 2.1 About Actors
DROP TABLE IF EXISTS actors;
CREATE TABLE actors (
    actor_id INT PRIMARY KEY IDENTITY(1,1),
    actor_name VARCHAR(255) NOT NULL,
    bio TEXT
);

DROP TABLE IF EXISTS movies_actors;
CREATE TABLE movies_actors (
    movie_id INT FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    actor_id INT FOREIGN KEY (actor_id) REFERENCES actors(actor_id),
    PRIMARY KEY (movie_id, actor_id)
);

--- 2.2 About Genres
DROP TABLE IF EXISTS genres;
CREATE TABLE genres (
    genre_id INT PRIMARY KEY IDENTITY(1,1),
    genre_name VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS movies_genres;
CREATE TABLE movies_genres (
    movie_id INT FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    genre_id INT FOREIGN KEY (genre_id) REFERENCES genres(genre_id),
    PRIMARY KEY (movie_id, genre_id)
);

--- 3. About Studios
DROP TABLE IF EXISTS studios;
CREATE TABLE studios (
    studio_id INT PRIMARY KEY IDENTITY(1,1),
    studio_name VARCHAR(255) NOT NULL,
    screen_type VARCHAR(255) NOT NULL CONSTRAINT screen_type_ck CHECK (screen_type IN ('2D', '3D', '4D')),
);

--- 3.1 About Seats
DROP TABLE IF EXISTS seats;
CREATE TABLE seats (
    seat_id INT PRIMARY KEY IDENTITY(1,1),
    studio_id INT FOREIGN KEY (studio_id) REFERENCES studios(studio_id),
    seat_row INT NOT NULL,
    seat_column INT NOT NULL,
);


--- 4. About Transactions
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
    payment_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT FOREIGN KEY (user_id) REFERENCES users(id),
    amount FLOAT NOT NULL,
    payment_method VARCHAR(255) NOT NULL CONSTRAINT payment_method_ck CHECK (payment_method IN ('Credit Card', 'Debit Card', 'Cash')),
    payment_time DATETIME NOT NULL DEFAULT GETDATE()
);

--- 5. About Schedules and Tickets
DROP TABLE IF EXISTS schedules;
CREATE TABLE schedules (
    schedule_id INT PRIMARY KEY IDENTITY(1,1),
    movie_id INT FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    studio_id INT FOREIGN KEY (studio_id) REFERENCES studios(studio_id),
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price FLOAT NOT NULL,
);

DROP TABLE IF EXISTS tickets;
CREATE TABLE tickets (
    ticket_id INT PRIMARY KEY IDENTITY(1,1),
    schedule_id INT FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id),
    seat_id INT FOREIGN KEY (seat_id) REFERENCES seats(seat_id),
    user_id INT FOREIGN KEY (user_id) REFERENCES users(id), -- if customer_id, then it is booked by customer, if clerk_id, then it is booked by clerk, if manager_id, then it is booked by manager
    ticket_status VARCHAR(255) NOT NULL CONSTRAINT ticket_status_ck CHECK (ticket_status IN ('Booked', 'Cancelled', 'Available')),
    payment_id INT FOREIGN KEY (payment_id) REFERENCES transactions(payment_id),
);


--- 6. About Customer's Special Functionalities
DROP TABLE IF EXISTS customer_feedbacks;
CREATE TABLE customer_feedbacks (
    id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT FOREIGN KEY (customer_id) REFERENCES users_customers(customer_id),
    comment VARCHAR(255) NOT NULL,
    dateAndTime DATETIME NOT NULL
);

DROP TABLE IF EXISTS customer_MovieReviews;
CREATE TABLE customer_MovieReviews (
    id INT PRIMARY KEY IDENTITY(1,1),
    customer_id INT FOREIGN KEY (customer_id) REFERENCES users_customers(customer_id),
    movie_id INT FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    rating INT NOT NULL CONSTRAINT rating_ck CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    dateAndTime DATETIME NOT NULL
);

--- 7. About Manager's Special Functionalities
DROP TABLE IF EXISTS events;
CREATE TABLE events (
    event_id INT PRIMARY KEY IDENTITY(1,1),
    event_name VARCHAR(255) NOT NULL,
    event_description TEXT,
    event_start_time DATETIME NOT NULL,
    event_end_time DATETIME NOT NULL,
    studio_id INT FOREIGN KEY (studio_id) REFERENCES studios(studio_id),
    event_revenue FLOAT NOT NULL,
    manager_id INT FOREIGN KEY (manager_id) REFERENCES users_managers(manager_id)
);