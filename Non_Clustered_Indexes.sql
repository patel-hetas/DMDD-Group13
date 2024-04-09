-- Index for movies by name for faster search
CREATE NONCLUSTERED INDEX IDX_MovieName
ON movies (movie_name);
GO


-- Index for tickets by status for quick filtering
CREATE NONCLUSTERED INDEX IDX_TicketStatus
ON tickets (ticket_status);
GO


-- Index for transactions by user for efficient lookup
CREATE NONCLUSTERED INDEX IDX_Transactions_User
ON transactions (user_id);
GO


-- Index on Tickets by Schedule ID to Quickly Find All Tickets for a Given Schedule
CREATE NONCLUSTERED INDEX IDX_TicketsBySchedule
ON tickets (schedule_id);
GO


-- Index on Movie Schedules by Movie ID for Efficient Schedule Lookups
CREATE NONCLUSTERED INDEX IDX_ScheduleByMovie
ON schedules (movie_id);
GO


-- Index on Users by Role for Quick Access Control Checks
CREATE NONCLUSTERED INDEX IDX_UserRole
ON users ([role]);
GO