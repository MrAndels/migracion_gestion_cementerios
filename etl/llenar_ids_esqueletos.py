# llenar_ids_esqueletos.py
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

# (columna _id de esqueletos, tabla padre, columna de factura en el padre)
PARES = [("inhumado_id", "inhumados", "factura"),
         ("exhumado_id", "exhumados", "factura_ex"),
         ("cremado_id", "cremados", "factura")]

con = pymysql.connect(**CONF)
cur = con.cursor()

for fk, padre, cf in PARES:
    cur.execute(f"""
        UPDATE esqueletos e
        JOIN (
          SELECT `{cf}` AS factura,
                 CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                      AS UNSIGNED) AS pid
          FROM `{padre}`
          WHERE `{cf}` IS NOT NULL
          GROUP BY `{cf}`
          HAVING SUM(borrado = 0) < 2
        ) p ON p.factura = e.factura
        SET e.`{fk}` = p.pid
        WHERE e.id > 0
    """)
    con.commit()

cur.execute("SELECT COUNT(*) FROM esqueletos WHERE borrado = 0 AND factura IS NOT NULL")
total = cur.fetchone()[0]
print(f"esqueletos activas con factura: {total:,}\n")
print(f"{'columna':26s} {'enlazadas':>10s} {'sin enlace':>11s} {'repetidas':>10s} {'sin padre':>10s}")

for fk, padre, cf in PARES:
    cur.execute(f"SELECT COALESCE(SUM(`{fk}` IS NOT NULL), 0) FROM esqueletos "
                f"WHERE borrado = 0 AND factura IS NOT NULL")
    enl = int(cur.fetchone()[0])
    cur.execute(f"""SELECT COUNT(*) FROM esqueletos e
                    WHERE e.borrado = 0 AND e.factura IS NOT NULL AND e.`{fk}` IS NULL
                      AND (SELECT COUNT(*) FROM `{padre}` p
                           WHERE p.`{cf}` = e.factura AND p.borrado = 0) >= 2""")
    rep = cur.fetchone()[0]
    sin = total - enl
    print(f"{'esqueletos.' + fk:26s} {enl:>10,} {sin:>11,} {rep:>10,} {sin - rep:>10,}")

con.close()
print("\nListo.")