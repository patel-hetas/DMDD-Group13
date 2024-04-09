-- Alter table for role_ck constraint in users table
ALTER TABLE users
ADD CONSTRAINT role_ck CHECK ([role] IN ('Customer', 'Clerk', 'Manager'));

-- Alter table for payment_status_ck constraint in transactions table
ALTER TABLE transactions
ADD CONSTRAINT payment_status_ck CHECK (payment_status IN ('Successfull', 'Cancelled', 'Pending'));

-- Alter table for age_rating_ck constraint in movies table
ALTER TABLE movies
ADD CONSTRAINT age_rating_ck CHECK (age_rating IN ('G', 'PG', 'PG-13', 'R', 'NC-17'));

-- Alter table for screen_type_ck constraint in studios table
ALTER TABLE studios
ADD CONSTRAINT screen_type_ck CHECK (screen_type IN ('2D', '3D', '4D'));

-- Alter table for ticket_status_ck constraint in tickets table
ALTER TABLE tickets
ADD CONSTRAINT ticket_status_ck CHECK (ticket_status IN ('Booked', 'Cancelled', 'Available','Payment Pending'));

-- Alter table for rating_ck constraint in customer_MovieReviews table
ALTER TABLE customer_MovieReviews
ADD CONSTRAINT rating_ck CHECK (rating BETWEEN 1 AND 5);
