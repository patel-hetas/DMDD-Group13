DROP DATABASE IF EXISTS ttms;
CREATE DATABASE ttms;
USE ttms;
GO

CREATE TABLE IF NOT EXISTS `user` (
    `id` INT IDENTITY(1,1) PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL,
    `password` VARCHAR(50) NOT NULL,
    `phone` VARCHAR(15) NOT NULL,
    `role` VARCHAR(255) NOT NULL CONSTRAINT role_ck CHECK (role IN ('Customer', 'Clerk', 'Manager'))
);
