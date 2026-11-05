from lector_dbf import buscar_ruta, leer_dbf_completo

# Caracteres no ASCII que son normales en español
NORMALES = set("áéíóúüñÁÉÍÓÚÜÑ¿ºª°")

def _raros(s):
    return sum(1 for c in s if ord(c) > 127 and c not in NORMALES)

def arreglar_texto(s):
    """Elige entre cp1252 y cp850 la lectura con menos caracteres raros."""
    try:
        b = s.encode("latin-1")
    except UnicodeEncodeError:
        return s
    a = b.decode("cp1252", errors="replace")
    d = b.decode("cp850", errors="replace")
    return d if _raros(d) < _raros(a) else a

def limpiar(v):
    if isinstance(v, str):
        v = arreglar_texto(v).strip()
        return v if v != "" else None
    return v

def leer_dbf(tabla, avisos=None):
    """Devuelve las filas de la tabla (activas y borradas) con la clave "_borrado"."""
    return leer_dbf_completo(buscar_ruta(tabla), avisos)