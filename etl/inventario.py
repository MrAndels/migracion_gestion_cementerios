from pathlib import Path
from dbfread import DBF

CARPETA = Path("datos_originales/dbf")

TABLAS = [
    "bancos", "causa_muerte", "cementerios", "conciliacion", "consignaciones",
    "cremados", "detalle_fact", "devoluciones", "efectivo", "esqueletos",
    "estado_boveda", "exhumados", "factura", "forma_pago", "funerarias",
    "galerias", "inhumados", "inhumados_nn", "inventario", "items",
    "lugar_inh", "oficinas", "pabellon", "parentesco", "prop_lotes",
    "prop_unidades", "rc", "sector", "servicios", "tipo_id",
    "tipo_serv", "tipo_usuario",
]

archivos = {}
for f in CARPETA.rglob("*"):
    if f.suffix.lower() == ".dbf":
        archivos.setdefault(f.stem.lower(), []).append(f)

for tabla in TABLAS:
    candidatos = []
    for nombre in (tabla, "_" + tabla):
        candidatos += archivos.get(nombre, [])
    if not candidatos:
        print(f"{tabla:16} -> SIN ARCHIVO DBF")
        continue
    for f in candidatos:
        try:
            dbf = DBF(str(f), ignore_missing_memofile=True, char_decode_errors="replace")
            print(f"{tabla:16} -> {f.name:28} {len(dbf):>9} registros, {len(dbf.field_names)} campos")
        except Exception as e:
            print(f"{tabla:16} -> {f.name:28} ERROR: {e}")
            