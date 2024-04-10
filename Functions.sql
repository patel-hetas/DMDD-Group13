--- 0. About Encryption starts
DROP FUNCTION IF EXISTS fn_getEncryptedPassword;
GO
CREATE FUNCTION fn_getEncryptedPassword -- Get Encrypted Password
    (@password_not_encrypted VARCHAR(50))
RETURNS VARBINARY(512)
AS
BEGIN
    DECLARE @password_encrypted VARBINARY(512);
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
--- 0. About Encryption ends

-- UDF to get the revenue  of a company by movie id
DROP FUNCTION IF EXISTS GetRevenueByMovieID;
GO
CREATE FUNCTION GetRevenueByMovieID
    (@movie_id INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @revenue FLOAT;

    SELECT @revenue = SUM(s.price)  -- Aggregating the prices of all booked tickets
    FROM schedules s
    JOIN tickets t ON s.schedule_id = t.schedule_id
    WHERE s.movie_id = @movie_id AND t.ticket_status = 'Booked' AND t.user_id IS NOT NULL; -- Ensuring the ticket is booked and paid
    
    RETURN @revenue;
END;
GO
DECLARE @movieID INT = 1; 
SELECT dbo.GetRevenueByMovieID(@movieID) AS Revenue_For_Movie;
GO
 


-- UDF to calculate the seat occupancy based on movie
CREATE FUNCTION CalculateSeatOccupancyRate(@MovieID INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @TotalSeats INT, @OccupiedSeats INT
    SELECT @TotalSeats = COUNT(*) FROM seats
    JOIN studios ON seats.studio_id = studios.studio_id
    JOIN schedules ON studios.studio_id = schedules.studio_id
    WHERE schedules.movie_id = @MovieID
 
    SELECT @OccupiedSeats = COUNT(*) FROM tickets
    JOIN schedules ON tickets.schedule_id = schedules.schedule_id
    WHERE schedules.movie_id = @MovieID AND ticket_status = 'Booked'
 
    IF @TotalSeats = 0
        RETURN 0
    RETURN CAST(@OccupiedSeats AS FLOAT) / CAST(@TotalSeats AS FLOAT)
END
GO

DECLARE @movieID INT = 1; 
SELECT dbo.CalculateSeatOccupancyRate(@movieID) AS Occupancy_Rate_For_Movie_1;
GO


-- UDF to calculate age based on DOB
CREATE FUNCTION CalculateAge
(
    @BirthDate DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEDIFF(YEAR, @BirthDate, GETDATE()) - 
           CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @BirthDate, GETDATE()), @BirthDate) > GETDATE() THEN 1 ELSE 0 END;
END;
GO

DECLARE @birthDate DATE = '1990-04-09';
SELECT dbo.CalculateAge(@birthDate) AS Age;
GO


--  Calculate average duartion of movies watched by user 
CREATE FUNCTION GetAverageMovieDurationByUser(@UserID INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @AverageDuration FLOAT
    SELECT @AverageDuration = AVG(CAST(duration AS FLOAT))
    FROM movies
    JOIN schedules ON movies.movie_id = schedules.movie_id
    JOIN tickets ON schedules.schedule_id = tickets.schedule_id
    WHERE tickets.user_id = @UserID AND tickets.ticket_status = 'Booked'
    RETURN ISNULL(@AverageDuration, 0)
END
GO

DECLARE @userID INT = 5; 
SELECT dbo.GetAverageMovieDurationByUser(@userID) AS AverageMovieDuration;
GO

-- UDF to get review category
CREATE FUNCTION GetReviewCategory(@rating INT)
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
END;
RETURN @category
END;
GO

DECLARE @rating INT = 4; 
SELECT dbo.GetReviewCategory(@rating) AS ReviewCategory;
GO
 
-- UDF to calculate move duration
CREATE FUNCTION GetScheduleDuration (@StartTime DATETIME, @EndTime DATETIME)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @TotalMinutes INT = DATEDIFF(MINUTE, @StartTime, @EndTime);
	DECLARE @Hours INT = @TotalMinutes / 60;
	DECLARE @Minutes INT = @TotalMinutes % 60;
	RETURN CAST(@Hours AS VARCHAR(10)) + 'h ' + RIGHT('0' + CAST(@Minutes AS VARCHAR(2)), 2) + 'm';
END;
GO

DECLARE @TestStartTime DATETIME = '2024-01-01T09:00:00';
DECLARE @TestEndTime DATETIME = '2024-01-01T11:15:00';
SELECT dbo.GetScheduleDuration(@TestStartTime, @TestEndTime) AS DurationTestResult;