"""
Lector de archivos .dbf (FoxPro) hecho a mano.

Por qué existe: la librería dbfread (1) se salta las filas borradas y (2) deja de
leer cuando encuentra un registro corrupto en medio del archivo (le pasa a FACTURA
y a consignaciones). Este lector lee TODAS las filas, marca cuáles estaban
borradas y avisa de los registros corruptos en vez de callarse.

Uso:
    from lector_dbf import leer_dbf_completo
    avisos = []
    for reg in leer_dbf_completo("datos_originales/dbf/servicios.dbf", avisos):
        print(reg["_borrado"], reg["SERVICIO"])
"""
import datetime
import struct
import sys
from pathlib import Path

CARPETA_DBF = Path(__file__).resolve().parent.parent / "datos_originales" / "dbf" / "CONSORCIO" / "SYSACYH" / "DATA"


def buscar_ruta(tabla, carpeta=CARPETA_DBF):
    """Encuentra tabla.dbf sin importar mayúsculas o minúsculas."""
    for archivo in Path(carpeta).iterdir():
        if archivo.suffix.lower() == ".dbf" and archivo.stem.lower() == tabla.lower():
            return archivo
    raise FileNotFoundError(f"No encontré {tabla}.dbf en {carpeta}")


def _leer_encabezado(f):
    """Devuelve (longitud_encabezado, longitud_registro, lista_de_campos)."""
    cab = f.read(32)
    long_enc, long_reg = struct.unpack("<HH", cab[8:12])
    campos, pos = [], 1                      # el byte 0 de cada registro es la marca de borrado
    resto = f.read(long_enc - 32)
    i = 0
    while i + 32 <= len(resto) and resto[i] != 0x0D:
        d = resto[i:i + 32]
        nombre = d[:11].split(b"\x00")[0].decode("latin-1")
        tipo, largo, dec = chr(d[11]), d[16], d[17]
        campos.append((nombre, tipo, pos, largo, dec))
        pos += largo
        i += 32
    return long_enc, long_reg, campos


def _cargar_memo(ruta):
    """Carga el archivo .fpt (textos largos) si existe; si no, devuelve None."""
    for p in ruta.parent.iterdir():
        if p.stem.lower() == ruta.stem.lower() and p.suffix.lower() == ".fpt":
            datos = p.read_bytes()
            return datos, struct.unpack(">H", datos[6:8])[0]
    return None


def _convertir(tipo, bruto, dec, memo):
    if tipo == "C":
        return bruto.decode("latin-1").rstrip(" \x00")
    if tipo in "NF":
        s = bruto.strip()
        if not s:
            return None
        try:
            return float(s) if dec else int(s)
        except ValueError:
            return None
    if tipo == "D":
        s = bruto.strip()
        if not s or s == b"0" * 8:
            return None
        try:
            return datetime.datetime.strptime(s.decode("ascii"), "%Y%m%d").date()
        except ValueError:
            return None
    if tipo == "L":
        b = bruto[:1]
        return True if b in b"YyTt" else False if b in b"NnFf" else None
    if tipo == "T":
        dia, ms = struct.unpack("<ii", bruto[:8])
        if dia == 0:
            return None
        try:
            return (datetime.datetime.fromordinal(dia - 1721425)
                    + datetime.timedelta(milliseconds=ms))
        except (ValueError, OverflowError):
            return None
    if tipo in "MG":                          # texto largo guardado en el .fpt
        if memo is None:
            return None
        datos, bloque = memo
        ptr = struct.unpack("<I", bruto[:4])[0] if len(bruto) == 4 else int(bruto.strip() or 0)
        if ptr == 0:
            return None
        ini = ptr * bloque
        tipo_bloque, largo = struct.unpack(">II", datos[ini:ini + 8])
        if tipo_bloque != 1:                  # 1 = texto; 0 = imagen (no se migra)
            return None
        return datos[ini + 8:ini + 8 + largo].decode("latin-1")
    return None


def leer_dbf_completo(ruta, avisos=None, por_lote=5000):
    """
    Recorre TODAS las filas de un .dbf y devuelve un diccionario por fila.
    Cada diccionario trae además la clave "_borrado" (True si estaba borrada).
    Los registros corruptos se omiten y se anotan en la lista `avisos`.
    """
    ruta = Path(ruta)
    memo = _cargar_memo(ruta)
    with open(ruta, "rb") as f:
        long_enc, long_reg, campos = _leer_encabezado(f)
        total = (ruta.stat().st_size - long_enc) // long_reg
        campos_utiles = [c for c in campos if c[1] != "0"]    # "0" = banderas internas de nulos
        f.seek(long_enc)
        numero = 0
        while numero < total:
            leer = min(por_lote, total - numero)
            bloque = f.read(leer * long_reg)
            for k in range(leer):
                numero += 1
                reg = bloque[k * long_reg:(k + 1) * long_reg]
                marca = reg[0]
                if marca not in (0x20, 0x2A):                 # solo " " (activa) o "*" (borrada) son válidas
                    if avisos is not None:
                        avisos.append(f"{ruta.name}: registro corrupto en la fila {numero:,} (marca {marca:#04x}), omitido")
                    continue
                fila = {n: _convertir(t, reg[p:p + l], d, memo) for n, t, p, l, d in campos_utiles}
                fila["_borrado"] = (marca == 0x2A)
                yield fila


if __name__ == "__main__":
    # Prueba rápida:  python etl/lector_dbf.py servicios
    tabla = sys.argv[1]
    carpeta = Path(sys.argv[2]) if len(sys.argv) > 2 else CARPETA_DBF
    avisos, activas, borradas = [], 0, 0
    for r in leer_dbf_completo(buscar_ruta(tabla, carpeta), avisos):
        if r["_borrado"]:
            borradas += 1
        else:
            activas += 1
    print(f"{tabla}: activas {activas:,} | borradas {borradas:,} | total {activas + borradas:,}")
    for a in avisos:
        print("AVISO:", a)