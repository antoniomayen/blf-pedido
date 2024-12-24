import mysql.connector
from mysql.connector import Error

class DatabaseConnection:
    def __init__(self):
        self.config = {
            'host': 'db-blfmaster',
            'user': 'root',
            'password': 'blf123',
            'database': 'blfmaster',
            'port': '3306'
        }

    def __enter__(self):
        try:
            self.connection = mysql.connector.connect(**self.config)
            return self.connection
        except Error as e:
            print(f"Error connecting to MySQL: {e}")
            raise

    def __exit__(self, exc_type, exc_val, exc_tb):
        if hasattr(self, 'connection'):
            self.connection.close()