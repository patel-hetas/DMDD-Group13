-- View 1: Report on Current Movies and Showtimes
-- This view will help users to quickly find current movies and their showtimes.
CREATE VIEW vw_CurrentMoviesShowtimes AS
SELECT 
    m.movie_name,
    m.age_rating,
    s.start_time,
    s.end_time,
    s.price,
    st.studio_name,
    st.screen_type
FROM 
    movies m
JOIN 
    schedules s ON m.movie_id = s.movie_id
JOIN 
    studios st ON s.studio_id = st.studio_id
WHERE 
    s.start_time > GETDATE();
GO



-- View 2: Report on Ticket Sales by Movie
-- This view will show the number of tickets sold per movie, which can be useful for financial reporting and performance tracking.
CREATE VIEW vw_TicketSalesByMovie AS
SELECT 
    m.movie_name,
    COUNT(t.ticket_id) AS TicketsSold,
    SUM(s.price) AS TotalSales
FROM 
    movies m
JOIN 
    schedules s ON m.movie_id = s.movie_id
JOIN 
    tickets t ON t.schedule_id = s.schedule_id AND t.ticket_status = 'Booked'
GROUP BY 
    m.movie_name;
GO


-- View 3: Report on Customer Feedback
-- This view aggregates customer feedback, which can be important for customer service and quality control.
CREATE VIEW vw_CustomerFeedbackSummary AS
SELECT 
    u.displayName,
    uc.isVIP,
    COUNT(f.id) AS TotalFeedback,
    AVG(mr.rating) AS AverageMovieRating
FROM 
    users_customers uc
JOIN 
    users u ON uc.customer_id = u.id
LEFT JOIN 
    customer_feedbacks f ON uc.customer_id = f.customer_id
LEFT JOIN 
    customer_MovieReviews mr ON uc.customer_id = mr.customer_id
GROUP BY 
    u.displayName, uc.isVIP;
GO



-- View 4: Report on Daily Sales
-- This view provides a daily summary of ticket sales, including total revenue and the number 
-- of tickets sold per day. It's useful for financial tracking and trend analysis.
CREATE VIEW vw_DailySalesReport AS
SELECT 
    CAST(t.payment_time AS DATE) AS SaleDate,
    COUNT(t.payment_id) AS TotalTicketsSold,
    SUM(t.amount) AS TotalRevenue
FROM 
    transactions t
GROUP BY 
    CAST(t.payment_time AS DATE);
GO



-- View 5: Most Popular Movies
-- This view identifies the most popular movies based on the number of tickets sold. 
-- This can help in marketing and promotional efforts, as well as in planning future screenings.
CREATE VIEW vw_MostPopularMovies AS
SELECT 
    m.movie_name,
    COUNT(t.ticket_id) AS TicketsSold
FROM 
    movies m
JOIN 
    schedules s ON m.movie_id = s.movie_id
JOIN 
    tickets t ON s.schedule_id = t.schedule_id
WHERE 
    t.ticket_status = 'Booked'
GROUP BY 
    m.movie_name
ORDER BY 
    TicketsSold DESC;
GO
