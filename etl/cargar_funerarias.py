import os
import sys
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


def a_entero(v):
    """Convierte a entero; si no se puede, devuelve None."""
    try:
        return None if v is None else int(v)
    except (ValueError, TypeError):
        return None


avisos = []
filas = []
for reg in leer_dbf("funerarias", avisos):
    r = {k.lower(): limpiar(v) for k, v in reg.items()}
    filas.append({
        "cod_fun": r.get("cod_fun"),
        "nit": r.get("nit"),
        "nombre": r.get("nombre"),
        "representa": r.get("representa"),
        "direccion": r.get("direccion"),
        "telefono": r.get("telefono"),
        "id_orig": a_entero(r.get("id")),
        "fec_acc": r.get("fec_acc"),
        "disponible": a_entero(r.get("disponible")),
        "borrado": 1 if reg["_borrado"] else 0,
    })

activas = sum(1 for f in filas if f["borrado"] == 0)
borradas = sum(1 for f in filas if f["borrado"] == 1)
print(f"Leídos del DBF: {len(filas)} registros (activas {activas}, borradas {borradas})")
for a in avisos:
    print("AVISO:", a)

columnas = list(filas[0].keys())
sql = text(
    f"INSERT INTO funerarias ({', '.join(columnas)}) "
    f"VALUES ({', '.join(':' + c for c in columnas)})"
)

with engine.connect() as conn:
    antes = conn.execute(text("SELECT COUNT(*) FROM funerarias")).scalar()
    if antes > 0:
        if not recargar:
            print(f"funerarias ya tiene {antes} registros. "
                  f"Para vaciarla y volver a cargar usa: --recargar")
            sys.exit()
        print(f"Vaciando funerarias ({antes} registros)...")
        conn.execute(text("DELETE FROM funerarias"))
        conn.execute(text("ALTER TABLE funerarias AUTO_INCREMENT = 1"))
        conn.commit()
    conn.execute(sql, filas)
    conn.commit()
    despues = conn.execute(text("SELECT COUNT(*) FROM funerarias")).scalar()

print(f"Cargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")