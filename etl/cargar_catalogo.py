import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL
from utiles import limpiar, leer_dbf

load_dotenv()
tabla = sys.argv[1].lower()
recargar = "--recargar" in sys.argv[2:]

# Columnas con nombre distinto: {tabla: {columna_mysql: columna_dbf}}
MAPEO = {
    "tipo_id": {"id_orig": "id"},
    "items": {"join_orig": "join"},
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

todas = [c["name"] for c in insp.get_columns(tabla)]

# Columnas de MySQL, sin id ni borrado (id lo pone MySQL; borrado lo calculamos aparte)
cols_mysql = [c for c in todas if c.lower() not in ("id", "borrado")]
tiene_borrado = "borrado" in [c.lower() for c in todas]
cols_insert = cols_mysql + (["borrado"] if tiene_borrado else [])

mapa = MAPEO.get(tabla, {})

avisos = []
filas = []
for reg in leer_dbf(tabla, avisos):
    fila = {k.lower(): limpiar(v) for k, v in reg.items()}
    nueva = {c: fila.get(mapa.get(c, c).lower()) for c in cols_mysql}
    if tiene_borrado:
        nueva["borrado"] = 1 if reg["_borrado"] else 0
    filas.append(nueva)

activas = sum(1 for f in filas if f.get("borrado") == 0)
borradas = sum(1 for f in filas if f.get("borrado") == 1)
print(f"Leídos del DBF: {len(filas)} registros (activas {activas}, borradas {borradas})")
for a in avisos:
    print("AVISO:", a)

columnas = ", ".join(cols_insert)
marcadores = ", ".join(f":{c}" for c in cols_insert)
sql = text(f"INSERT INTO {tabla} ({columnas}) VALUES ({marcadores})")

with engine.connect() as conn:
    antes = conn.execute(text(f"SELECT COUNT(*) FROM {tabla}")).scalar()
    if antes > 0:
        if not recargar:
            print(f"La tabla {tabla} ya tiene {antes} registros. "
                  f"Para vaciarla y volver a cargar usa: --recargar")
            sys.exit()
        print(f"Vaciando {tabla} ({antes} registros)...")
        conn.execute(text(f"DELETE FROM {tabla}"))
        conn.execute(text(f"ALTER TABLE {tabla} AUTO_INCREMENT = 1"))
        conn.commit()
    conn.execute(sql, filas)
    conn.commit()
    despues = conn.execute(text(f"SELECT COUNT(*) FROM {tabla}")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")