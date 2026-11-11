# app/db.py
import pymysql
from config import Config


def get_db():
    """Abre una conexión nueva a MySQL."""
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


def ejecutar(sql, params=None):
    """Ejecuta un INSERT/UPDATE y devuelve el id insertado (si aplica)."""
    conn = get_db()
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            conn.commit()
            return cur.lastrowid
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()