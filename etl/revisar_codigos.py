# revisar_codigos.py  (solo lectura)
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

# (tabla hija, columna hija, catálogo, columna de código del catálogo)
PARES = [
    ("servicios", "cementerio", "cementerios", "cementerio"),
    ("servicios", "tipo_serv", "tipo_serv", "tipo_serv"),
    ("servicios", "item", "items", "item"),
    ("servicios", "itemold", "items", "item"),
    ("factura", "cementerio", "cementerios", "cementerio"),
    ("factura", "forma_pago", "forma_pago", "forma_pago"),
    ("consignaciones", "banco", "bancos", "banco"),
    ("conciliacion", "cementerio", "cementerios", "cementerio"),
    ("conciliacion", "banco", "bancos", "banco"),
    ("rc", "banco", "bancos", "banco"),
    ("pabellon", "cementerio", "cementerios", "cementerio"),
    ("inventario", "cementerio", "cementerios", "cementerio"),
    ("inventario", "estado", "estado_boveda", "estado"),
    ("prop_lotes", "cementerio", "cementerios", "cementerio"),
    ("prop_unidades", "cementerio", "cementerios", "cementerio"),
]
# Las tablas de personas comparten los mismos catálogos
for t in ("inhumados", "exhumados", "cremados", "inhumados_nn"):
    PARES += [
        (t, "cementerio", "cementerios", "cementerio"),
        (t, "causa_muer", "causa_muerte", "causa_muer"),
        (t, "tipo_usuar", "tipo_usuario", "tipo_usuar"),
        (t, "servicio", "items", "item"),
    ]
for t in ("inhumados", "exhumados", "inhumados_nn"):
    PARES += [
        (t, "sector", "sector", "sector"),
        (t, "lugar_inh", "lugar_inh", "lugar_inh"),
        (t, "galeria", "galerias", "galeria"),
    ]
for t in ("inhumados", "exhumados"):
    PARES.append((t, "parentesco", "parentesco", "parentesco"))
for t in ("inhumados", "cremados"):
    PARES.append((t, "tipo_id", "tipo_id", "id_orig"))

con = pymysql.connect(**CONF)
cur = con.cursor()

for hija, col, cat, cat_col in PARES:
    cur.execute(f"""
        SELECT h.`{col}`, COUNT(*) AS filas
        FROM `{hija}` h
        LEFT JOIN `{cat}` c ON c.`{cat_col}` = h.`{col}`
        WHERE h.borrado = 0 AND h.`{col}` IS NOT NULL AND c.id IS NULL
        GROUP BY h.`{col}`
        ORDER BY filas DESC
    """)
    filas = cur.fetchall()
    if not filas:
        continue
    total = sum(f[1] for f in filas)
    muestra = ", ".join(f"{v!r}×{n:,}" for v, n in filas[:8])
    extra = f" (+{len(filas) - 8} más)" if len(filas) > 8 else ""
    print(f"{hija}.{col} -> {cat}.{cat_col}: {total:,} filas, "
          f"{len(filas)} códigos: {muestra}{extra}")

con.close()
print("\nFin. Si una columna no aparece, todos sus códigos existen en el catálogo.")