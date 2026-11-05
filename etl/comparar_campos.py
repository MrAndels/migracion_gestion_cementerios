import os
from pathlib import Path
from dotenv import load_dotenv
from dbfread import DBF
from sqlalchemy import create_engine, inspect
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
insp = inspect(create_engine(url))

CARPETA = Path("datos_originales/dbf")
archivos = {}
for f in CARPETA.rglob("*"):
    if f.suffix.lower() == ".dbf":
        archivos.setdefault(f.stem.lower(), []).append(f)

for tabla in sorted(insp.get_table_names()):
    cols_mysql = {c["name"].lower() for c in insp.get_columns(tabla)}
    for nombre in (tabla, "_" + tabla):
        for f in archivos.get(nombre, []):
            dbf = DBF(str(f), ignore_missing_memofile=True, char_decode_errors="replace")
            cols_dbf = {c.lower() for c in dbf.field_names}
            solo_dbf = sorted(cols_dbf - cols_mysql)
            solo_mysql = sorted(cols_mysql - cols_dbf)
            estado = "IGUALES" if not solo_dbf and not solo_mysql else "DIFERENCIAS"
            print(f"\n{tabla} <- {f.name}: {estado} (DBF {len(cols_dbf)} / MySQL {len(cols_mysql)})")
            if solo_dbf:
                print("   solo en DBF:  ", ", ".join(solo_dbf))
            if solo_mysql:
                print("   solo en MySQL:", ", ".join(solo_mysql))
                