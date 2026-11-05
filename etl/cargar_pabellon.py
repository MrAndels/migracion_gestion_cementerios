import os
import sys
import csv
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from utiles import limpiar, leer_dbf

load_dotenv()
recargar = "--recargar" in sys.argv[1:]

url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)

# 1. Diccionario código -> id del catálogo de cementerios
with engine.connect() as conn:
    cementerios = {
        codigo: id_
        for id_, codigo in conn.execute(text("SELECT id, cementerio FROM cementerios"))
    }
print(f"Cementerios en el catálogo: {cementerios}")

# 2. Leer el DBF (activas y borradas) y transformar
avisos = []
filas = []
rechazados = []
for reg in leer_dbf("pabellon", avisos):
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
        "borrado": 1 if reg["_borrado"] else 0,
    }
    if fila["cementerio_id"] is None:
        rechazados.append(fila)
    filas.append(fila)

activas = sum(1 for f in filas if f["borrado"] == 0)
borradas = sum(1 for f in filas if f["borrado"] == 1)
print(f"Leídos del DBF: {len(filas)} registros (activas {activas}, borradas {borradas})")
for a in avisos:
    print("AVISO:", a)

sin_act = sum(1 for f in rechazados if f["borrado"] == 0)
print(f"Sin cementerio en el catálogo: {len(rechazados)} (activas {sin_act}, borradas {len(rechazados) - sin_act})")

# 3. Reporte de rechazados (la carpeta salidas/ está en el .gitignore)
if rechazados:
    Path("salidas").mkdir(exist_ok=True)
    ruta = Path("salidas/pabellon_sin_cementerio.csv")
    with open(ruta, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=rechazados[0].keys())
        w.writeheader()
        w.writerows(rechazados)
    print(f"Reporte guardado en {ruta}")

# 4. Cargar
columnas = list(filas[0].keys())
sql = text(
    f"INSERT INTO pabellon ({', '.join(columnas)}) "
    f"VALUES ({', '.join(':' + c for c in columnas)})"
)

with engine.connect() as conn:
    antes = conn.execute(text("SELECT COUNT(*) FROM pabellon")).scalar()
    if antes > 0:
        if not recargar:
            print(f"La tabla pabellon ya tiene {antes} registros. "
                  f"Para vaciarla y volver a cargar usa: --recargar")
            sys.exit()
        print(f"Vaciando pabellon ({antes} registros)...")
        conn.execute(text("DELETE FROM pabellon"))
        conn.execute(text("ALTER TABLE pabellon AUTO_INCREMENT = 1"))
        conn.commit()
    conn.execute(sql, filas)
    conn.commit()
    despues = conn.execute(text("SELECT COUNT(*) FROM pabellon")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")