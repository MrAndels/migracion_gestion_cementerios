# app/rutas/consulta.py
import hashlib
import hmac
import re
import unicodedata
from datetime import date, datetime

from flask import Blueprint, render_template, request

from config import Config
from db import consultar, ejecutar
from extensiones import limiter
from rutas.ingresos import _catalogo, _etiqueta

consulta_bp = Blueprint("consulta", __name__, url_prefix="/consulta")

MENSAJE_FALLO = "No encontramos coincidencias con los datos ingresados."
MAX_RESULTADOS = 20


def _sql_doc(col):
    """Compara documentos sin puntos, espacios ni dígito de verificación."""
    return (f"REPLACE(REPLACE(REPLACE(SUBSTRING_INDEX(TRIM({col}), '-', 1), "
            f"'.', ''), ' ', ''), ',', '')")


_RESP = _sql_doc("nit_deudo")
_CED = _sql_doc("cedula")

SQL_CEDULA = f"""
SELECT 'Inhumación' AS servicio, nombre, fecha_inh AS fecha, cementerio,
       sector, pabellon, galeria, lugar_inh, lugar_no, fila
FROM v_inhumados_activos WHERE {_RESP} = %s OR {_CED} = %s
UNION ALL
SELECT 'Cremación', nombre, fecha_cre, cementerio,
       NULL, NULL, NULL, NULL, NULL, NULL
FROM v_cremados_activos WHERE {_RESP} = %s OR {_CED} = %s
UNION ALL
SELECT 'Exhumación', nombre, fecha_exh, cementerio,
       sector, pabellon, galeria, lugar_inh, lugar_no, fila
FROM v_exhumados_activos WHERE {_RESP} = %s
ORDER BY fecha DESC
LIMIT 200
"""


def _sql_nombre(n):
    cond = " AND ".join(["nombre LIKE %s"] * n)
    return f"""
    SELECT 'Inhumación' AS servicio, nombre, fecha_inh AS fecha, cementerio,
           sector, pabellon, galeria, lugar_inh, lugar_no, fila
    FROM v_inhumados_activos WHERE {cond}
    UNION ALL
    SELECT 'Cremación', nombre, fecha_cre, cementerio,
           NULL, NULL, NULL, NULL, NULL, NULL
    FROM v_cremados_activos WHERE {cond}
    UNION ALL
    SELECT 'Exhumación', nombre, fecha_exh, cementerio,
           sector, pabellon, galeria, lugar_inh, lugar_no, fila
    FROM v_exhumados_activos WHERE {cond}
    ORDER BY fecha DESC
    LIMIT 300
    """


def _palabras(texto):
    """Palabras en mayúscula y sin tildes."""
    s = unicodedata.normalize("NFD", str(texto or ""))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn").upper()
    return re.findall(r"[A-Z0-9]+", s)


def _contiene(nombre, palabras, cobertura=0.0):
    """¿Están todas las palabras escritas en el nombre guardado?
    Con 'cobertura' se exige además que cubran esa parte del nombre."""
    guardadas = set(_palabras(nombre))
    if not all(p in guardadas for p in palabras):
        return False
    return (not guardadas) or len(palabras) / len(guardadas) >= cobertura


def _hash(clave):
    return hmac.new(Config.SECRET_KEY.encode(), clave.encode(),
                    hashlib.sha256).hexdigest()


def _registrar(clave, resultado, n):
    """Anota la consulta sin guardar la cédula ni el nombre."""
    try:
        ejecutar(
            "INSERT INTO log_consultas (ip, doc_hash, resultado, n_registros) "
            "VALUES (%s, %s, %s, %s)",
            (request.remote_addr, _hash(clave), resultado, n),
        )
    except Exception:
        pass  # el registro nunca debe tumbar la consulta


def _fecha(v):
    if isinstance(v, (date, datetime)):
        return v.strftime("%d/%m/%Y")
    return str(v) if v else "Sin fecha"


def _ubicacion(f, sectores, galerias, lugares):
    partes = []
    if f["sector"]:
        partes.append("Sector " + _etiqueta(sectores, f["sector"]))
    if f["pabellon"]:
        partes.append("Pabellón " + str(f["pabellon"]).strip())
    if f["galeria"]:
        partes.append("Galería " + _etiqueta(galerias, f["galeria"]))
    if f["lugar_inh"]:
        partes.append(_etiqueta(lugares, f["lugar_inh"]))
    if f["lugar_no"]:
        partes.append("N.º " + str(f["lugar_no"]).strip())
    if f["fila"]:
        partes.append("Fila " + str(f["fila"]).strip())
    return " · ".join(partes) or "No registrada"


def _pagina(resultados=None, error=None, truncado=False, valores=None):
    return render_template("consulta.html", resultados=resultados, error=error,
                           truncado=truncado, valores=valores or {})


@consulta_bp.route("/", methods=["GET", "POST"])
@limiter.limit("5 per minute;30 per hour", methods=["POST"])
def consulta():
    if request.method == "GET":
        return _pagina()

    cedula = re.sub(r"\D", "", request.form.get("cedula", ""))
    palabras = list(dict.fromkeys(_palabras(request.form.get("nombre", ""))))[:6]
    valores = {"cedula": request.form.get("cedula", "")[:20],
               "nombre": request.form.get("nombre", "")[:80]}

    if not cedula and not palabras:
        return _pagina(error="Escribe tu cédula o el nombre completo del fallecido.",
                       valores=valores)
    if cedula and not (5 <= len(cedula) <= 15 and set(cedula) != {"0"}):
        return _pagina(error="La cédula debe tener solo números, entre 5 y 15 dígitos.",
                       valores=valores)
    if not cedula and (len(palabras) < 2 or sum(len(p) for p in palabras) < 6):
        return _pagina(error="Sin cédula, escribe el nombre completo del fallecido "
                             "(nombre y apellidos).", valores=valores)
    if cedula and palabras and sum(len(p) for p in palabras) < 3:
        return _pagina(error="El nombre debe tener al menos 3 letras.",
                       valores=valores)

    if cedula:
        filas = consultar(SQL_CEDULA, (cedula,) * 5)
        if palabras:
            filas = [f for f in filas if _contiene(f["nombre"], palabras)]
        clave = cedula
    else:
        filas = consultar(_sql_nombre(len(palabras)),
                          tuple(f"%{p}%" for p in palabras) * 3)
        filas = [f for f in filas if _contiene(f["nombre"], palabras, 0.6)]
        clave = "N:" + " ".join(sorted(palabras))

    if not filas:
        _registrar(clave, "fallo", 0)
        return _pagina(error=MENSAJE_FALLO, valores=valores)

    truncado = len(filas) > MAX_RESULTADOS
    filas = filas[:MAX_RESULTADOS]

    cementerios = _catalogo("v_cementerios_activos", ("cementerio",))
    sectores = _catalogo("v_sector_activos", ("sector", "codigo", "id"))
    galerias = _catalogo("v_galerias_activos", ("galeria", "codigo", "id"))
    lugares = _catalogo("v_lugar_inh_activos", ("lugar_inh", "codigo", "id"))

    resultados = [dict(
        servicio=f["servicio"],
        fallecido=str(f["nombre"] or "").strip(),
        fecha=_fecha(f["fecha"]),
        cementerio=_etiqueta(cementerios, f["cementerio"]),
        ubicacion=_ubicacion(f, sectores, galerias, lugares),
    ) for f in filas]

    _registrar(clave, "ok", len(resultados))
    return _pagina(resultados=resultados, truncado=truncado)