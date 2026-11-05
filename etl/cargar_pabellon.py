import os
import sys
import csv
from pathlib import Path
from dotenv import load_dotenv
from dbfread import DBF
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

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

def limpiar(v):
    if isinstance(v, str):
        v = v.strip()
        return v if v != "" else None
    return v

# 1. Diccionario código -> id del catálogo de cementerios
with engine.connect() as conn:
    cementerios = {
        codigo: id_
        for id_, codigo in conn.execute(text("SELECT id, cementerio FROM cementerios"))
    }
print(f"Cementerios en el catálogo: {cementerios}")

# 2. Leer el DBF
CARPETA = Path("datos_originales/dbf")
archivo = next(f for f in CARPETA.rglob("*")
               if f.suffix.lower() == ".dbf" and f.stem.lower() == "pabellon")
dbf = DBF(str(archivo), ignore_missing_memofile=True, char_decode_errors="replace")

# 3. Transformar
filas = []
rechazados = []
for reg in dbf:
    r = {k.lower(): limpiar(v) for k, v in reg.items()}
    fila = {
        "pabellon": r.get("pabellon"),
        "nombre": r.get("nombre"),
        "cementerio": r.get("cementerio"),
        "sector": r.get("sector"),
        "manzana": r.get("manzana"),
        "lote": r.get("lote"),
        "fec_acc": r.get("fec_acc"),
        "cementerio_id": cementerios.get(r.get("cementerio")),
    }
    if fila["cementerio_id"] is None:
        rechazados.append(fila)
    filas.append(fila)

print(f"Leídos del DBF: {len(filas)} registros")
print(f"Sin cementerio en el catálogo: {len(rechazados)}")

# 4. Reporte de rechazados (la carpeta salidas/ está en el .gitignore)
if rechazados:
    Path("salidas").mkdir(exist_ok=True)
    ruta = Path("salidas/pabellon_sin_cementerio.csv")
    with open(ruta, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=rechazados[0].keys())
        w.writeheader()
        w.writerows(rechazados)
    print(f"Reporte guardado en {ruta}")

# 5. Cargar
columnas = list(filas[0].keys())
sql = text(
    f"INSERT INTO pabellon ({', '.join(columnas)}) "
    f"VALUES ({', '.join(':' + c for c in columnas)})"
)

with engine.begin() as conn:
    antes = conn.execute(text("SELECT COUNT(*) FROM pabellon")).scalar()
    if antes > 0:
        print(f"La tabla pabellon ya tiene {antes} registros. No cargo nada para evitar duplicados.")
        sys.exit()
    conn.execute(sql, filas)
    despues = conn.execute(text("SELECT COUNT(*) FROM pabellon")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")