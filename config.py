import psycopg2
from dotenv import load_dotenv
import os



load_dotenv()

conn = psycopg2.connect(
    database=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT")
)

cursor = conn.cursor()

cursor.execute("SELECT * FROM pedido_proveedor")
data = cursor.fetchall()
for d in data:
    print(d)



