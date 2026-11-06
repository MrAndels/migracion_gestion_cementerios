# llenar_ids_compuestos.py
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

# (tabla hija, columna _id, columnas del código en la hija, padre, columnas en el padre)
PARES = [
    ("inventario", "pabellon_id", ["cementerio", "pabellon"],
     "pabellon", ["cementerio", "pabellon"]),
    ("prop_unidades", "prop_lote_id", ["cementerio", "subsector", "manzana", "lote"],
     "prop_lotes", ["cementerio", "subsector", "manzana", "lote"]),
]

con = pymysql.connect(**CONF)
cur = con.cursor()

for t, fk, hc, padre, pc in PARES:
    sel = ", ".join(f"`{c}`" for c in pc)
    padre_ok = " AND ".join(f"`{c}` IS NOT NULL" for c in pc)
    union = " AND ".join(f"p.`{b}` = h.`{a}`" for a, b in zip(hc, pc))
    # Solo códigos NO repetidos entre las filas activas del padre; si el código
    # solo existe borrado, se usa la de menor id.
    cur.execute(f"""
        UPDATE `{t}` h
        JOIN (
          SELECT {sel},
                 CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                      AS UNSIGNED) AS pid
          FROM `{padre}` WHERE {padre_ok}
          GROUP BY {sel}
          HAVING SUM(borrado = 0) < 2
        ) p ON {union}
        SET h.`{fk}` = p.pid
        WHERE h.id > 0
    """)
    con.commit()

print(f"{'columna':32s} {'activas con código':>18s} {'sin enlace':>11s}")
for t, fk, hc, padre, pc in PARES:
    cols = ", ".join(f"`{c}`" for c in hc)
    cond = " AND ".join(f"`{c}` IS NOT NULL" for c in hc)
    cur.execute(f"SELECT COUNT(*), COALESCE(SUM(`{fk}` IS NULL), 0) "
                f"FROM `{t}` WHERE borrado = 0 AND {cond}")
    total, sin = cur.fetchone()
    print(f"{t + '.' + fk:32s} {total:>18,} {int(sin):>11,}")
    cur.execute(f"SELECT {cols}, COUNT(*) AS n FROM `{t}` "
                f"WHERE borrado = 0 AND {cond} AND `{fk}` IS NULL "
                f"GROUP BY {cols} ORDER BY n DESC LIMIT 5")
    for fila in cur.fetchall():
        print("    sin enlace:", fila[:-1], "->", fila[-1], "filas")

con.close()
print("\nListo.")