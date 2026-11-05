import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from dbfread import DBF
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL

load_dotenv()
tabla = sys.argv[1].lower()

# Columnas con nombre distinto: {tabla: {columna_mysql: columna_dbf}}
MAPEO = {
    "tipo_id": {"id_orig": "id"},
}

url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)
insp = inspect(engine)

# Columnas de MySQL, sin id ni borrado (los maneja MySQL)
cols_mysql = [c["name"] for c in insp.get_columns(tabla)
              if c["name"].lower() not in ("id", "borrado")]

# Buscar el .dbf de esa tabla
CARPETA = Path("datos_originales/dbf")
archivo = next(f for f in CARPETA.rglob("*")
               if f.suffix.lower() == ".dbf" and f.stem.lower() == tabla)

dbf = DBF(str(archivo), ignore_missing_memofile=True, char_decode_errors="replace")

def limpiar(v):
    if isinstance(v, str):
        v = v.strip()
        return v if v != "" else None
    return v

filas = []
for reg in dbf:
    fila = {k.lower(): limpiar(v) for k, v in reg.items()}
    mapa = MAPEO.get(tabla, {})
    filas.append({c: fila.get(mapa.get(c, c).lower()) for c in cols_mysql})

print(f"Leídos del DBF: {len(filas)} registros")

columnas = ", ".join(cols_mysql)
marcadores = ", ".join(f":{c}" for c in cols_mysql)
sql = text(f"INSERT INTO {tabla} ({columnas}) VALUES ({marcadores})")

with engine.begin() as conn:
    antes = conn.execute(text(f"SELECT COUNT(*) FROM {tabla}")).scalar()
    if antes > 0:
        print(f"La tabla {tabla} ya tiene {antes} registros. No cargo nada para evitar duplicados.")
        sys.exit()
    conn.execute(sql, filas)
    despues = conn.execute(text(f"SELECT COUNT(*) FROM {tabla}")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")