import os
import sys
from pathlib import Path
from dotenv import load_dotenv
from dbfread import DBF
from sqlalchemy import create_engine, inspect
from sqlalchemy.engine import URL

load_dotenv()
tabla = sys.argv[1].lower()

url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
insp = inspect(create_engine(url))

print(f"=== MySQL: {tabla} ===")
for c in insp.get_columns(tabla):
    print(f"  {c['name']:20} {str(c['type']):20} nulo={c['nullable']}")

CARPETA = Path("datos_originales/dbf")
for f in CARPETA.rglob("*"):
    if f.suffix.lower() == ".dbf" and f.stem.lower() == tabla:
        dbf = DBF(str(f), ignore_missing_memofile=True, char_decode_errors="replace")
        print(f"\n=== DBF: {f.name} ===")
        for fld in dbf.fields:
            print(f"  {fld.name:20} tipo={fld.type} largo={fld.length} dec={fld.decimal_count}")
        print("\nPrimeros registros:")
        for i, reg in enumerate(dbf):
            print("  ", dict(reg))
            if i >= 4:
                break