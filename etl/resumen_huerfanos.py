# resumen_huerfanos.py
import csv
import os
import re
from pathlib import Path
import pymysql
from dotenv import load_dotenv

load_dotenv()
CONF = dict(host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            charset="utf8mb4")

con = pymysql.connect(**CONF)
cur = con.cursor()
db = CONF["database"]

# Columnas de cada tabla (para validar los códigos que salen del comentario)
cur.execute("SELECT table_name, column_name FROM information_schema.columns "
            "WHERE table_schema = %s", (db,))
columnas = {}
for t, c in cur.fetchall():
    columnas.setdefault(t, set()).add(c)

# Las columnas _id con llave foránea, sin contar las tablas de respaldo
cur.execute("""
    SELECT c.table_name, c.column_name, c.column_comment
    FROM information_schema.columns c
    JOIN information_schema.tables t
      ON t.table_schema = c.table_schema AND t.table_name = c.table_name
    WHERE c.table_schema = %s AND t.table_type = 'BASE TABLE'
      AND c.table_name NOT LIKE %s AND c.column_comment LIKE 'FK a%%'
    ORDER BY c.table_name, c.ordinal_position
""", (db, r"%\_bak"))
enlaces = cur.fetchall()

resultados, omitidas = [], []
for t, fk, comentario in enlaces:
    m = re.search(r"original en ([^)]+)\)", comentario)
    cods = [x for x in re.findall(r"\w+", m.group(1)) if x in columnas[t]] if m else []
    if not cods:
        omitidas.append(f"{t}.{fk}")
        continue
    cond = " AND ".join(f"`{c}` IS NOT NULL AND `{c}` <> ''" for c in cods)
    cur.execute(f"SELECT COUNT(*), COALESCE(SUM(`{fk}` IS NULL), 0) "
                f"FROM `{t}` WHERE borrado = 0 AND {cond}")
    total, sin = cur.fetchone()
    total, sin = int(total), int(sin)
    pct = 100 * sin / total if total else 0
    resultados.append((t, fk, "+".join(cods), total, sin, pct))

resultados.sort(key=lambda r: r[4], reverse=True)

print(f"Columnas _id revisadas: {len(resultados)} de {len(enlaces)}")
print(f"Completas (0 sin enlace): {sum(1 for r in resultados if r[4] == 0)}\n")
print(f"{'columna':34s} {'código':22s} {'con código':>11s} {'sin enlace':>11s} {'%':>6s}")
for t, fk, cod, total, sin, pct in resultados:
    if sin > 0:
        print(f"{t + '.' + fk:34s} {cod:22s} {total:>11,} {sin:>11,} {pct:>6.1f}")
if omitidas:
    print("\nNo pude leer el código de:", ", ".join(omitidas))

Path("salidas").mkdir(exist_ok=True)
with open("salidas/resumen_huerfanos.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["columna", "codigo", "activas_con_codigo", "sin_enlace", "porcentaje"])
    for t, fk, cod, total, sin, pct in resultados:
        w.writerow([f"{t}.{fk}", cod, total, sin, f"{pct:.2f}"])
print("\nGuardado en salidas/resumen_huerfanos.csv")

con.close()