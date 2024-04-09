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

-- Cancel Tickets Once a Movie Schedule is Deleted
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