
import tkinter as tk
from tkinter import messagebox
import pyodbc
import streamlit as st
import pandas as pd

# Database connection parameters
DRIVER_NAME = 'SQL Server'
SERVER_NAME = 'Mihir\MSSQLSERVER07'  # Update with your actual server name
DATABASE_NAME = 'ttms5'  # Update with your actual database name

USERNAME = 'MIHIR\\mihir'  # Update with your actual username
PASSWORD = ''  # Update with your actual password


# Function to create database connection
def create_connection():
    connection_string = f"""
        DRIVER={{{DRIVER_NAME}}};
        SERVER={SERVER_NAME};
        DATABASE={DATABASE_NAME};
        UID={USERNAME};
        PWD={PASSWORD};
        Trusted_Connection=yes;
    """
    try:
        conn = pyodbc.connect(connection_string)
        return conn
    except Exception as e:
        messagebox.showerror("Database Connection Error", str(e))
        return None
    
# STREAMLIT
    
# Function to get data from a specific table
def get_table_data(table_name, search_query=None):
    conn = create_connection()
    query = f"SELECT * FROM {table_name}"
    if search_query:
        query += f" WHERE {search_query}"
    query += ";"
    df = pd.read_sql(query, conn)
    conn.close()
    return df



def run_stored_procedure(procedure_name):
    conn = create_connection()
    if conn is not None:
        cursor = conn.cursor()
        try:
            cursor.execute(f"EXEC {procedure_name}")
            # If the stored procedure returns result sets, fetch them
            if cursor.description is not None:
                result_set = cursor.fetchall()
                columns = [column[0] for column in cursor.description]
                df = pd.DataFrame.from_records(result_set, columns=columns)
                return df
            else:
                st.info(f"The stored procedure '{procedure_name}' was executed but returned no results.")
                return pd.DataFrame()
        except Exception as e:
            st.error(f"An error occurred: {e}")
            return pd.DataFrame()
        finally:
            cursor.close()
            conn.close()

def run_stored_procedure_with_params(procedure_name, params):
    conn = create_connection()
    if conn is not None:
        cursor = conn.cursor()
        try:
            # Build the SQL command with placeholders for the parameters
            placeholders = ', '.join(['?'] * len(params))  # '?' placeholders for parameters
            sql_command = f"EXEC {procedure_name} {placeholders}"
            cursor.execute(sql_command, params)

            # Check if the stored procedure returns any result sets
            if cursor.description:
                # If there are results, convert to DataFrame
                df = pd.DataFrame.from_records(cursor.fetchall(), columns=[desc[0] for desc in cursor.description])
                st.dataframe(df)
            else:
                # If no results, just indicate the procedure executed successfully
                st.success(f"Stored procedure '{procedure_name}' executed successfully.")

            conn.commit()
        except pyodbc.Error as e:
            st.error(f"Database error: {str(e)}")
            conn.rollback()
        except Exception as e:
            st.error(f"An unexpected error occurred: {str(e)}")
        finally:
            cursor.close()
            conn.close()


# Function to update a specific row
def update_row(table_name, primary_key_column, primary_key_value, column_to_update, new_value):
    conn = create_connection()
    cursor = conn.cursor()
    # Build the SQL UPDATE statement dynamically
    sql_statement = f"UPDATE {table_name} SET {column_to_update} = ? WHERE {primary_key_column} = ?"
    cursor.execute(sql_statement, (new_value, primary_key_value))
    conn.commit()
    cursor.close()
    conn.close()


def delete_user_with_dependencies(user_id):
    conn = create_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("EXEC DeleteUserWithDependencies ?", (user_id,))
        conn.commit()
        st.success("User and all related records deleted successfully.")
    except pyodbc.IntegrityError as e:
        st.error(f"Integrity error: {e}")
        conn.rollback()
    except Exception as e:
        st.error(f"An error occurred: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()


# Function to fetch movies
def get_movies():
    conn = create_connection()
    if conn:
        query = "SELECT movie_id, movie_name FROM movies"
        try:
            df = pd.read_sql(query, conn)
            return df
        except Exception as e:
            st.error(f"Error fetching movies: {e}")
            return pd.DataFrame()
        finally:
            conn.close()
    else:
        return pd.DataFrame()

# Function to fetch schedules for a movie
def get_schedules(movie_id):
    conn = create_connection()
    if conn:
        query = "SELECT schedule_id, start_time, end_time FROM schedules WHERE movie_id = ?"
        try:
            df = pd.read_sql(query, conn, params=(movie_id,))
            return df
        except Exception as e:
            st.error(f"Error fetching schedules: {e}")
            return pd.DataFrame()
        finally:
            conn.close()
    else:
        return pd.DataFrame()
    
def get_tickets(schedule_id):
    conn = create_connection()
    if conn:
        query = "SELECT seat_id, ticket_id, ticket_status FROM tickets WHERE schedule_id = ?"
        try:
            df = pd.read_sql(query, conn, params=(schedule_id,))
            return df
        except Exception as e:
            st.error(f"Error fetching tickets: {e}")
            return pd.DataFrame()
        finally:
            conn.close()
    else:
        return pd.DataFrame()

def book_tickets(schedule_id, seat_id, user_id):
    conn = create_connection()
    if conn:
        cursor = conn.cursor()
        try:
            cursor.execute("EXEC sp_bookTicket ?, ?, ?", (user_id, seat_id, schedule_id))
            conn.commit()
            st.success("Ticket booked successfully!")
        except Exception as e:
            st.error(f"Error booking tickets: {e}")
        finally:
            cursor.close()
            conn.close()


# Streamlit app for displaying tables and running stored procedures
def main():
    st.title('TTMS Database Management')

# Sidebar for actions
    st.sidebar.title("Actions")
    actions = ['View Tables', 'Run Stored Procedure', 'Update a Row', 'Delete Record', 'Book Ticket']
    selected_action = st.sidebar.radio("Choose an action", actions)

    # View Tables
    if selected_action == 'View Tables':
            # Sidebar for table selection
        st.sidebar.title("Database Tables")
        table_names = [
            'actors', 'customer_feedbacks', 'customer_MovieReviews',
            'events', 'genres', 'movies', 'movies_actors',
            'movies_genres', 'schedules', 'seats', 'studios',
            'tickets', 'transactions', 'users', 'users_customers',
            'users_clerks', 'users_managers'
        ]
        selected_table = st.sidebar.selectbox("Select a table", table_names)

        # Optional: Text input for search query
        search_query = st.sidebar.text_input("Enter a SQL WHERE clause to filter the results (optional)")

        # Button to display table data
        if st.sidebar.button('Display Data'):
            st.subheader(f"Data from {selected_table}")
            with st.spinner(f"Loading data from {selected_table}..."):
                try:
                    df = get_table_data(selected_table, search_query)
                    st.write(df)
                except Exception as e:
                    st.error(f"An error occurred: {e}")

    # Run Stored Procedure
    elif selected_action == 'Run Stored Procedure':
        st.subheader('Run a Stored Procedure')

        proc_option = st.radio("Choose Procedure Type", ['With Parameters', 'Without Parameters'])

        if proc_option == 'With Parameters':
            st.subheader("Run Procedure With Parameters")
            # Dictionary of stored procedures with required parameters
            stored_procedures_with_params = {
                'sp_modifyUserByUserID': ['user_id', 'username', 'displayName', 'password_not_encrypted', 'phone'],
                'CheckTicketAvailability' : ['seatId' ,'scheduleId', 'x'],
                'sp_BookTicket' : ['userId', 'seatId', 'scheduleId']
                # Add other stored procedures that require parameters here
            }
            procedure_with_params = st.selectbox(
                "Select a stored procedure",
                list(stored_procedures_with_params.keys())
            )
            if procedure_with_params:
                params = [st.text_input(f"Enter {param}") for param in stored_procedures_with_params[procedure_with_params]]
                if st.button('Run Procedure with Params'):
                    # Assume `params` is a list of parameters collected from the user via text_input in Streamlit
                    if procedure_with_params and all(params):
                        with st.spinner(f"Running {procedure_with_params}..."):
                            run_stored_procedure_with_params(procedure_with_params, params)
                    else:
                        st.error("Please fill in all required fields.")

        elif proc_option == 'Without Parameters':
            st.subheader("Run Procedure Without Parameters")
            # List of stored procedures without parameters
            stored_procedures_without_params = ['checking']  # Add others as needed
            procedure_without_params = st.selectbox(
                "Select a stored procedure",
                stored_procedures_without_params
            )
            if st.button('Run Procedure without Params'):
                with st.spinner(f"Running {procedure_without_params}..."):
                    df = run_stored_procedure(procedure_without_params)
                    if not df.empty:
                        st.dataframe(df)
                    else:
                        st.success(f"{procedure_without_params} executed with no results to display.")




    
    # Update Records
    elif selected_action == 'Update a Row':
        st.subheader('Update Records')
        # Let user choose the table
        table_to_update = st.selectbox("Choose a table to update", get_table_names())
        
        # Retrieve primary key column name for the chosen table
        primary_key_column = get_primary_key_column(table_to_update)
        
        # Displaying records to user for choosing which one to update
        st.write("Choose a record to update:")
        df = get_table_data(table_to_update)
        selected_record = st.selectbox('Which record do you want to update?', df[primary_key_column])
        
        # Get a dict mapping column names to current values for selected record
        record_values = df[df[primary_key_column] == selected_record].iloc[0].to_dict()

        # Let user choose the column to update
        column_to_update = st.selectbox("Choose a column to update", df.columns)
        
        # Display current value and ask for new value
        current_value = record_values[column_to_update]
        st.write(f"Current value: {current_value}")
        new_value = st.text_input("New value")

        if st.button('Update Record'):
            update_row(table_to_update, primary_key_column, selected_record, column_to_update, new_value)
            st.success("Record updated successfully.")

    # Delete Record
    elif selected_action == 'Delete Record':
        st.subheader('Delete a Record')

        with st.form("delete_user_form"):
            st.write("Enter the ID of the user to delete:")
            user_id = st.number_input("User ID", min_value=1, step=1)
            submit_button = st.form_submit_button("Delete User")

        if submit_button and user_id:
            result_message = delete_user_with_dependencies(user_id)
            if result_message:
                st.success(result_message)


    elif selected_action == 'Book Ticket':
        st.subheader('Book a ticket')
        # with st.form("Book Ticket"):
    
        # Input box for the user to enter their user ID
        user_id = st.text_input('Enter your user ID:')

        # Button to save the user ID
        if st.button('Save User ID'):
            # You can now use the user_id variable as needed
            st.write(f'User ID {user_id} saved successfully!')

        # For demonstration, display the entered user ID
        if user_id:
            st.write(f'Current User ID: {user_id}')

        # Step 1: Select a movie
        movies_df = get_movies()
        movie_choices = {row['movie_name']: row['movie_id'] for _, row in movies_df.iterrows()}
        selected_movie = st.selectbox("Select a movie", options=list(movie_choices.keys()))
        selected_movie_id = movie_choices[selected_movie]

        # Step 2: Select a schedule for the movie
        schedules_df = get_schedules(selected_movie_id)
        schedule_choices = {f"{row['start_time']}": row['schedule_id'] for _, row in schedules_df.iterrows()}
        selected_schedule = st.selectbox("Select a schedule", options=list(schedule_choices.keys()))
        selected_schedule_id = schedule_choices[selected_schedule]

        # Step 3: Show available tickets for the selected schedule
        st.header('Select Ticket')
        available_tickets_df = get_tickets(selected_schedule_id)
        if not available_tickets_df.empty:
            ticket_id_options = available_tickets_df['seat_id'].tolist()
            selected_ticket_id = st.selectbox("Select a ticket", options=ticket_id_options)

            # Step 4: Book the selected ticket
            #user_id = 1  # Replace with actual user ID
            if st.button("Book Ticket"):
                book_tickets(selected_schedule_id, selected_ticket_id, user_id)
        else:
            st.error('No available tickets for this schedule.')

# Utility function to get the list of table names
def get_table_names():
    # This should query the database system tables to get the list of table names
    # Example (SQL Server): SELECT table_name FROM information_schema.tables WHERE table_type = 'BASE TABLE'
    return ['actors', 'users', 'movies']  # Replace with dynamic retrieval

# Utility function to get the primary key column of a table
def get_primary_key_column(table_name):
    # This should query the database system tables to get the primary key column for a given table
    # Example (SQL Server): SELECT column_name FROM information_schema.key_column_usage WHERE table_name = 'your_table_name'
    return 'id'  # Replace with dynamic retrieval

if __name__ == "__main__":
    main()