# llenar_ids_funerarias.py
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()
CONF = dict(host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            charset="utf8mb4")

TABLAS = ["factura", "inhumados", "cremados"]

con = pymysql.connect(**CONF)
cur = con.cursor()

for t in TABLAS:
    cur.execute(f"""
        UPDATE `{t}` h
        JOIN (
          SELECT nit,
                 CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                      AS UNSIGNED) AS pid
          FROM funerarias
          WHERE nit IS NOT NULL
          GROUP BY nit
          HAVING SUM(borrado = 0) < 2
        ) p ON p.nit = h.funeraria
        SET h.funeraria_id = p.pid
        WHERE h.id > 0
    """)
    con.commit()

print(f"{'columna':28s} {'activas con código':>18s} {'sin enlace':>11s}")
for t in TABLAS:
    cur.execute(f"SELECT COUNT(*), COALESCE(SUM(funeraria_id IS NULL), 0) "
                f"FROM `{t}` WHERE borrado = 0 AND funeraria IS NOT NULL")
    total, sin = cur.fetchone()
    pct = 100 * int(sin) / total if total else 0
    print(f"{t + '.funeraria_id':28s} {total:>18,} {int(sin):>11,}  ({pct:.1f}%)")
    cur.execute(f"SELECT funeraria, COUNT(*) AS n FROM `{t}` "
                f"WHERE borrado = 0 AND funeraria IS NOT NULL AND funeraria_id IS NULL "
                f"GROUP BY funeraria ORDER BY n DESC LIMIT 5")
    for cod, n in cur.fetchall():
        print("    sin enlace:", repr(cod), "->", n, "filas")

con.close()
print("\nListo.")