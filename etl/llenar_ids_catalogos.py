# llenar_ids_catalogos.py
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

# (tabla hija, columna _id, columna de código en la hija, catálogo, código en el catálogo)
PARES = []
def add(tablas, fk, col, cat, cat_col):
    for t in tablas:
        PARES.append((t, fk, col, cat, cat_col))

PERSONAS = ["inhumados", "exhumados", "cremados", "inhumados_nn"]

add(["servicios", "factura", "conciliacion", "inhumados", "exhumados", "cremados",
     "inhumados_nn", "pabellon", "inventario", "prop_lotes", "prop_unidades"],
    "cementerio_id", "cementerio", "cementerios", "cementerio")
add(["servicios"], "tipo_serv_id", "tipo_serv", "tipo_serv", "tipo_serv")
add(["servicios"], "item_id", "item", "items", "item")
add(["servicios"], "itemold_id", "itemold", "items", "item")
add(["factura"], "forma_pago_id", "forma_pago", "forma_pago", "forma_pago")
add(["consignaciones", "conciliacion", "rc"], "banco_id", "banco", "bancos", "banco")
add(PERSONAS, "causa_muer_id", "causa_muer", "causa_muerte", "causa_muer")
add(PERSONAS, "tipo_usuar_id", "tipo_usuar", "tipo_usuario", "tipo_usuar")
add(PERSONAS, "servicio_id", "servicio", "items", "item")
add(["inhumados", "exhumados"], "parentesco_id", "parentesco", "parentesco", "parentesco")
add(["inhumados", "exhumados", "inhumados_nn"], "sector_id", "sector", "sector", "sector")
add(["inhumados", "exhumados", "inhumados_nn"], "lugar_inh_id", "lugar_inh", "lugar_inh", "lugar_inh")
add(["inhumados", "exhumados", "inhumados_nn"], "galeria_id", "galeria", "galerias", "galeria")
add(["inhumados", "cremados"], "tipo_identif_id", "tipo_id", "tipo_id", "id_orig")
add(["inventario"], "estado_id", "estado", "estado_boveda", "estado")

con = pymysql.connect(**CONF)
cur = con.cursor()

print(f"{'columna':45s} {'activas con código':>18s} {'sin enlace':>11s}")
for t, fk, col, cat, cc in PARES:
    # Un solo padre por código: se prefiere la fila activa y, si hay varias, el menor id
    cur.execute(f"""
        UPDATE `{t}` h
        JOIN (
          SELECT `{cc}` AS codigo,
                 CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                      AS UNSIGNED) AS pid
          FROM `{cat}` WHERE `{cc}` IS NOT NULL GROUP BY `{cc}`
        ) p ON p.codigo = h.`{col}`
        SET h.`{fk}` = p.pid
        WHERE h.id > 0
    """)
    con.commit()
    cur.execute(f"""
        SELECT COUNT(*), COALESCE(SUM(`{fk}` IS NULL), 0)
        FROM `{t}` WHERE borrado = 0 AND `{col}` IS NOT NULL
    """)
    total, sin = cur.fetchone()
    print(f"{t + '.' + fk:45s} {total:>18,} {int(sin):>11,}")

con.close()
print("\nListo.")