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


-- View 3: Available seats for a schedule
-- This view provides a daily summary of ticket availabilty for a particular schedule
CREATE VIEW vw_AvailableSeatsForSchedules AS
SELECT 
    t.schedule_id,
    s.studio_id,
    COUNT(*) AS available_seat_count
FROM 
    seats s
LEFT JOIN 
    tickets t ON s.seat_id = t.seat_id AND t.ticket_status = 'Available'
GROUP BY 
    t.schedule_id, s.studio_id;
GO


-- View 4: Most Popular Movies
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
GO
