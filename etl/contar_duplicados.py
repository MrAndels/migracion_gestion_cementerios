# contar_duplicados.py

import os
import pymysql
from dotenv import load_dotenv

load_dotenv()  # lee el archivo .env de la carpeta del proyecto

CONF = dict(host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            charset="utf8mb4")

con = pymysql.connect(**CONF)
cur = con.cursor()

cur.execute("""
    SELECT TABLE_NAME FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_TYPE = 'BASE TABLE'
      AND TABLE_NAME NOT LIKE '%\\_bak'
    ORDER BY TABLE_NAME
""")
tablas = [r[0] for r in cur.fetchall()]

resumen = []
for t in tablas:
    cur.execute("""
        SELECT COLUMN_NAME FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s
          AND COLUMN_NAME NOT IN ('id', 'borrado')
          AND COLUMN_NAME NOT IN (
              SELECT COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE
              WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s
                AND REFERENCED_TABLE_NAME IS NOT NULL)
        ORDER BY ORDINAL_POSITION
    """, (t, t))
    cols = [r[0] for r in cur.fetchall()]
    if not cols:
        continue
    lista = ", ".join(f"`{c}`" for c in cols)
    cur.execute(f"""
        SELECT COUNT(*) FROM (
          SELECT ROW_NUMBER() OVER (PARTITION BY {lista} ORDER BY id) AS rn
          FROM `{t}` WHERE borrado = 0
        ) x WHERE rn > 1
    """)
    n = cur.fetchone()[0]
    resumen.append((t, n))
    print(f"{t:20s} {n:>8,}")

print("\nTablas con sobrantes:")
for t, n in resumen:
    if n:
        print(f"  {t}: {n:,}")
con.close()