import os
import sys
import csv
from collections import Counter
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL
from utiles import limpiar, leer_dbf

load_dotenv()
recargar = "--recargar" in sys.argv[1:]

url = URL.create(
    "mysql+pymysql",
    username=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
    host=os.getenv("DB_HOST"),
    port=int(os.getenv("DB_PORT")),
    database=os.getenv("DB_NAME"),
)
engine = create_engine(url)
insp = inspect(engine)


def catalogo(tabla, columna=None):
    """Diccionario código viejo -> id nuevo.
    Si un código está repetido, gana el padre activo (el de menor id);
    si solo existe borrado, se usa el borrado."""
    if columna is None:
        # primera columna que no sea id ni borrado
        columna = next(c["name"] for c in insp.get_columns(tabla)
                       if c["name"].lower() not in ("id", "borrado"))
    with engine.connect() as conn:
        # Orden: borradas primero y ids de mayor a menor, así el último
        # que se escribe en el diccionario es el activo de menor id.
        d = {cod: id_ for id_, cod in
             conn.execute(text(
                 f"SELECT id, {columna} FROM {tabla} "
                 f"ORDER BY borrado DESC, id DESC"))}
    print(f"Catálogo {tabla} (columna {columna}): {len(d)} códigos")
    return d


cementerios = catalogo("cementerios", "cementerio")
tipos_serv = catalogo("tipo_serv")
items = catalogo("items", "item")


def a_int(v):
    """Convierte a entero; si no se puede, devuelve None."""
    try:
        return None if v is None else int(v)
    except (ValueError, TypeError):
        return None


avisos = []
filas = []
rechazados = []
memo_con_datos = 0

for reg in leer_dbf("servicios", avisos):
    r = {k.lower(): limpiar(v) for k, v in reg.items()}
    if r.get("itememo"):
        memo_con_datos += 1
    fila = {
        "servicio": r.get("servicio"),
        "join_orig": r.get("join"),
        "nombre": r.get("nombre"),
        "nombre1": r.get("nombre1"),
        "tipo_serv": r.get("tipo_serv"),
        "valor_serv": r.get("valor_serv"),
        "iva": r.get("iva"),
        "valor_iva": r.get("valor_iva"),
        "valor_aseo": r.get("valor_aseo"),
        "cementerio": r.get("cementerio"),
        "cod_contab": r.get("cod_contab"),
        "item": r.get("item"),
        "itemold": r.get("itemold"),
        "itemem": r.get("itemem"),
        "desc_orig": r.get("desc"),
        "reporte": a_int(r.get("reporte")),
        "cod_prod": r.get("cod_prod"),
        "des_prod": r.get("des_prod"),
        "sub_serv": r.get("sub_serv"),
        "est_serv": r.get("est_serv"),
        "cementerio_id": cementerios.get(r.get("cementerio")),
        "tipo_serv_id": tipos_serv.get(r.get("tipo_serv")),
        "item_id": items.get(r.get("item")),
        "itemold_id": items.get(r.get("itemold")),
        "borrado": 1 if reg["_borrado"] else 0,
    }
    # Huérfano = trae código pero no existe en el catálogo
    for codigo, llave in [("cementerio", "cementerio_id"),
                          ("tipo_serv", "tipo_serv_id"),
                          ("item", "item_id"),
                          ("itemold", "itemold_id")]:
        if fila[codigo] is not None and fila[llave] is None:
            rechazados.append({"servicio": fila["servicio"],
                               "campo": codigo, "codigo": fila[codigo],
                               "borrado": fila["borrado"]})
    filas.append(fila)

activas = sum(1 for f in filas if f["borrado"] == 0)
borradas = sum(1 for f in filas if f["borrado"] == 1)
print(f"\nLeídos del DBF: {len(filas)} registros (activas {activas}, borradas {borradas})")
for a in avisos:
    print("AVISO:", a)
print(f"ITEMEMO (memo) con datos, que NO se migran: {memo_con_datos}")
repetidos = {k: v for k, v in Counter(f["servicio"] for f in filas).items() if v > 1}
print(f"Códigos de servicio repetidos (con borradas): {len(repetidos)}")
huerf_act = sum(1 for x in rechazados if x["borrado"] == 0)
print(f"Códigos huérfanos (sin catálogo): {len(rechazados)} (en activas {huerf_act})")

if rechazados:
    Path("salidas").mkdir(exist_ok=True)
    ruta = Path("salidas/servicios_huerfanos.csv")
    with open(ruta, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=rechazados[0].keys())
        w.writeheader()
        w.writerows(rechazados)
    print(f"Reporte guardado en {ruta}")

columnas = list(filas[0].keys())
sql = text(
    f"INSERT INTO servicios ({', '.join(columnas)}) "
    f"VALUES ({', '.join(':' + c for c in columnas)})"
)

with engine.connect() as conn:
    antes = conn.execute(text("SELECT COUNT(*) FROM servicios")).scalar()
    if antes > 0:
        if not recargar:
            print(f"servicios ya tiene {antes} registros. "
                  f"Para vaciarla y volver a cargar usa: --recargar")
            sys.exit()
        print(f"Vaciando servicios ({antes} registros)...")
        conn.execute(text("DELETE FROM servicios"))
        conn.execute(text("ALTER TABLE servicios AUTO_INCREMENT = 1"))
        conn.commit()
    conn.execute(sql, filas)
    conn.commit()
    despues = conn.execute(text("SELECT COUNT(*) FROM servicios")).scalar()

print(f"\nCargados en MySQL: {despues} registros")
print("OK" if despues == len(filas) else "ATENCIÓN: los conteos no coinciden")