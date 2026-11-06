# llenar_ids_facturas.py
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

# (tabla hija, columna _id, código en la hija, padre, código en el padre)
PARES = [
    ("detalle_fact",   "factura_id",   "factura",   "factura",   "factura"),
    ("consignaciones", "factura_id",   "factura",   "factura",   "factura"),
    ("efectivo",       "factura_id",   "factura",   "factura",   "factura"),
    ("devoluciones",   "n_factura_id", "n_factura", "factura",   "factura"),
    ("detalle_fact",   "servicio_id",  "servicio",  "servicios", "servicio"),
]

con = pymysql.connect(**CONF)
cur = con.cursor()

print(f"{'columna':40s} {'activas con código':>18s} {'sin enlace':>11s}")
for t, fk, col, padre, pc in PARES:
    # Solo códigos que NO están repetidos entre las filas activas del padre.
    # Si un código solo existe en filas borradas, se usa la de menor id.
    cur.execute(f"""
        UPDATE `{t}` h
        JOIN (
          SELECT `{pc}` AS codigo,
                 CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                      AS UNSIGNED) AS pid
          FROM `{padre}` WHERE `{pc}` IS NOT NULL
          GROUP BY `{pc}`
          HAVING SUM(borrado = 0) < 2
        ) p ON p.codigo = h.`{col}`
        SET h.`{fk}` = p.pid
        WHERE h.id > 0
    """)
    con.commit()

# Segunda pasada: códigos de servicio repetidos (p. ej. 'HL') se desempatan
# con el cementerio de la línea (detalle_fact.cementeri1 = servicios.cementerio)
cur.execute("""
    UPDATE detalle_fact d
    JOIN (
      SELECT servicio, cementerio, MIN(id) AS pid
      FROM servicios
      WHERE borrado = 0 AND servicio IS NOT NULL AND cementerio IS NOT NULL
      GROUP BY servicio, cementerio
      HAVING COUNT(*) = 1
    ) p ON p.servicio = d.servicio AND p.cementerio = d.cementeri1
    SET d.servicio_id = p.pid
    WHERE d.id > 0 AND d.servicio_id IS NULL
""")
con.commit()

for t, fk, col, padre, pc in PARES:
    cur.execute(f"""
        SELECT COUNT(*), COALESCE(SUM(`{fk}` IS NULL), 0)
        FROM `{t}` WHERE borrado = 0 AND `{col}` IS NOT NULL
    """)
    total, sin = cur.fetchone()
    print(f"{t + '.' + fk:40s} {total:>18,} {int(sin):>11,}")

con.close()
print("\nListo.")