USE ttms;
GO

DECLARE @user_id_output INT
EXEC sp_createUser_customer 'customer1' , 'Customer 1' , 'password' , '123456789' , @user_id = @user_id_output OUTPUT;
