CREATE TRIGGER trg_GenerateTicketsOnNewSchedule
ON schedules
AFTER INSERT
AS
BEGIN
    DECLARE @new_schedule_id INT;
    DECLARE @studio_id INT;

    -- Get the ID of the newly inserted schedule
    SELECT TOP 1 @new_schedule_id = schedule_id, @studio_id = studio_id
    FROM schedules
    WHERE schedule_id IN (SELECT TOP 1 schedule_id FROM inserted);

    -- Generate tickets for each seat in the studio associated with the new schedule
    INSERT INTO tickets (schedule_id, seat_id, user_id, ticket_status, payment_id)
    SELECT 
        @new_schedule_id AS schedule_id,
        s.seat_id,
        NULL AS user_id,
        'Available' AS ticket_status,
        NULL AS payment_id
    FROM 
        seats s
    WHERE 
        s.studio_id = @studio_id;

    -- Additional actions can be performed here, such as sending notifications or updating other tables
END;
GO

-- Update Seat Availability When Ticket is Cancelled
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



-- Trigger for Updating Event Revenue
CREATE TRIGGER tr_update_event_revenue
ON transactions
AFTER INSERT
FOR EACH ROW
AS
BEGIN
    DECLARE @schedule_id INT;
    DECLARE @event_id INT;

    SELECT 
        @schedule_id = inserted.schedule_id
    FROM 
        inserted;

    SELECT 
        @event_id = e.event_id
    FROM 
        schedules s
    JOIN 
        events e ON s.studio_id = e.studio_id
    WHERE 
        s.schedule_id = @schedule_id;

    IF @event_id IS NOT NULL
    BEGIN
        DECLARE @revenue FLOAT;

        SELECT @revenue = SUM(amount)
        FROM transactions
        WHERE payment_id = inserted.payment_id;

        UPDATE events
        SET event_revenue = event_revenue + @revenue
        WHERE event_id = @event_id;
    END;
END;
GO



CREATE TRIGGER tr_remove_expired_event_tickets
ON events 
AFTER INSERT, UPDATE
AS
BEGIN
    -- Delete tickets associated with expired schedules
    DELETE
    FROM tickets 
    WHERE schedule_id IN(SELECT s.schedule_id
    FROM
        inserted AS i
        INNER JOIN schedules AS s
        ON i.studio_id = s.studio_id
    WHERE s.end_time < GETDATE()     );
END
GO