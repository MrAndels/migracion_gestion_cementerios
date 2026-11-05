import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from utiles import limpiar, leer_dbf

load_dotenv()
url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)

filas = []
for reg in leer_dbf("funerarias"):
    r = {k.lower(): limpiar(v) for k, v in reg.items()}
    filas.append({
        "cod_fun": r.get("cod_fun"),
        "nit": r.get("nit"),
        "nombre": r.get("nombre"),
        "representa": r.get("representa"),
        "direccion": r.get("direccion"),
        "telefono": r.get("telefono"),
        "id_orig": None if r.get("id") is None else int(r["id"]),
        "fec_acc": r.get("fec_acc"),
        "disponible": None if r.get("disponible") is None else int(r["disponible"]),
    })

print(f"Leídos del DBF: {len(filas)} registros")

columnas = list(filas[0].keys())
sql = text(
    f"INSERT INTO funerarias ({', '.join(columnas)}) "
    f"VALUES ({', '.join(':' + c for c in columnas)})"
)

with engine.begin() as conn:
    antes = conn.execute(text("SELECT COUNT(*) FROM funerarias")).scalar()
    if antes > 0:
        print(f"funerarias ya tiene {antes} registros. No cargo nada.")
        sys.exit()
    conn.execute(sql, filas)
    despues = conn.execute(text("SELECT COUNT(*) FROM funerarias")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")