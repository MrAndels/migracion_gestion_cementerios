
import pymysql
from config import Config


def get_db():
    """Abre una conexión nueva a MySQL. Úsala con 'with'."""
    return pymysql.connect(
        host=Config.DB_HOST,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        database=Config.DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        charset="utf8mb4",
    )


def consultar(sql, params=None):
    """Ejecuta un SELECT y devuelve todas las filas como lista de diccionarios."""
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()
    finally:
        conn.close()


def consultar_uno(sql, params=None):
    """Ejecuta un SELECT y devuelve solo la primera fila (o None)."""
    filas = consultar(sql, params)
    return filas[0] if filas else None