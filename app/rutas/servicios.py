# app/rutas/servicios.py
from flask import render_template, request

from db import consultar, consultar_uno

VERDE = "#0F6E56"
CLARO = "#5DCAA5"
GRIS = "#888780"

ANIO_DESDE = 2000

FUENTES = [
    ("Inhumados", "v_inhumados_activos", "fecha_inh", VERDE),
    ("Cremados", "v_cremados_activos", "fecha_cre", CLARO),
    ("Exhumados", "v_exhumados_activos", "fecha_exh", GRIS),
]

MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
         "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

TIPOS_ANIO = [("barras", "Barras"), ("apiladas", "Barras apiladas"),
              ("lineas", "Líneas"), ("puntos", "Puntos"), ("area", "Área")]
TIPOS_MES = [("lineas", "Líneas"), ("barras", "Barras"),
             ("apiladas", "Barras apiladas"), ("puntos", "Puntos"),
             ("area", "Área")]
TIPOS_CEMENTERIOS = [("barras", "Barras"), ("apiladas", "Barras apiladas"),
                     ("horizontales", "Barras horizontales"), ("dona", "Dona")]
TIPOS_REPARTO = [("horizontales", "Barras horizontales"), ("barras", "Barras"),
                 ("dona", "Dona"), ("torta", "Torta")]


def _donde(campo, anio=None, desde=None, cem=None):
    """Arma el WHERE con parámetros (nunca valores pegados al SQL)."""
    cond, params = ["1=1"], []
    if anio is not None:
        cond.append(f"YEAR({campo}) = %s")
        params.append(anio)
    if desde is not None:
        cond.append(f"YEAR({campo}) >= %s")
        params.append(desde)
    if cem:
        cond.append("cementerio = %s")
        params.append(cem)
    return " AND ".join(cond), tuple(params)


def _totales(anio, cem):
    salida = {}
    for nombre, vista, campo, _ in FUENTES:
        donde, params = _donde(campo, anio=anio, cem=cem)
        salida[nombre] = consultar_uno(
            f"SELECT COUNT(*) AS n FROM {vista} WHERE {donde}", params
        )["n"]
    return salida


def _anios_disponibles():
    tope = ANIO_DESDE
    for _, vista, campo, _ in FUENTES:
        fila = consultar_uno(f"SELECT MAX(YEAR({campo})) AS a FROM {vista}")
        if fila and fila["a"]:
            tope = max(tope, int(fila["a"]))
    return list(range(tope, ANIO_DESDE - 1, -1))


def _datos_anio(cem, sufijo):
    por_serie = []
    for nombre, vista, campo, color in FUENTES:
        donde, params = _donde(campo, desde=ANIO_DESDE, cem=cem)
        filas = consultar(
            f"SELECT YEAR({campo}) AS anio, COUNT(*) AS n FROM {vista} "
            f"WHERE {donde} GROUP BY anio ORDER BY anio", params
        )
        por_serie.append((nombre, color, {f["anio"]: f["n"] for f in filas}))

    todos = [a for _, _, d in por_serie for a in d]
    anios = list(range(min(todos), max(todos) + 1)) if todos else [ANIO_DESDE]
    series = [dict(nombre=n, color=c, valores=[int(d.get(a, 0)) for a in anios])
              for n, c, d in por_serie]
    return dict(id="anio", titulo=f"Servicios por año (desde {ANIO_DESDE}){sufijo}",
                periodo=True, tipos=TIPOS_ANIO, tipo_inicial="barras",
                categorico=False, categorias=anios, series=series,
                eje_x="Año", eje_y="Cantidad")


def _datos_mes(anio, cem, sufijo):
    series = []
    for nombre, vista, campo, color in FUENTES:
        if anio is None:
            donde, params = _donde(campo, desde=ANIO_DESDE, cem=cem)
        else:
            donde, params = _donde(campo, anio=anio, cem=cem)
        filas = consultar(
            f"SELECT MONTH({campo}) AS mes, COUNT(*) AS n FROM {vista} "
            f"WHERE {donde} GROUP BY mes", params
        )
        por_mes = {f["mes"]: f["n"] for f in filas}
        series.append(dict(nombre=nombre, color=color,
                           valores=[int(por_mes.get(m, 0)) for m in range(1, 13)]))
    cuando = str(anio) if anio else f"todos los años desde {ANIO_DESDE}"
    return dict(id="mes", titulo=f"Servicios por mes ({cuando}){sufijo}",
                periodo=False, tipos=TIPOS_MES, tipo_inicial="lineas",
                categorico=True, categorias=MESES, series=series,
                eje_x="Mes", eje_y="Cantidad")


def _datos_cementerios(anio, catalogo, sufijo):
    por_serie, suma = [], {}
    for nombre, vista, campo, color in FUENTES:
        donde, params = _donde(campo, anio=anio)
        filas = consultar(
            f"SELECT cementerio, COUNT(*) AS n FROM {vista} "
            f"WHERE {donde} GROUP BY cementerio", params
        )
        d = {}
        for f in filas:
            cod = None if f["cementerio"] is None else str(f["cementerio"]).strip()
            etiqueta = catalogo.get(cod) or "Sin dato"
            d[etiqueta] = d.get(etiqueta, 0) + f["n"]
            suma[etiqueta] = suma.get(etiqueta, 0) + f["n"]
        por_serie.append((nombre, color, d))

    nombres = sorted(suma, key=suma.get, reverse=True)
    series = [dict(nombre=n, color=c, valores=[int(d.get(x, 0)) for x in nombres])
              for n, c, d in por_serie]
    return dict(id="cementerios", titulo=f"Servicios por cementerio{sufijo}",
                periodo=False, tipos=TIPOS_CEMENTERIOS, tipo_inicial="barras",
                categorico=True, categorias=nombres, series=series,
                eje_x="Cementerio", eje_y="Cantidad")


def _datos_tipo_crema(anio, cem, sufijo):
    donde, params = _donde("fecha_cre", anio=anio, cem=cem)
    filas = consultar(
        f"SELECT tipo_crema, COUNT(*) AS n FROM v_cremados_activos "
        f"WHERE {donde} GROUP BY tipo_crema", params
    )
    suma = {}
    for f in filas:
        etiqueta = str(f["tipo_crema"] or "").strip() or "Sin dato"
        suma[etiqueta] = suma.get(etiqueta, 0) + f["n"]
    ordenado = sorted(suma.items(), key=lambda x: x[1], reverse=True)
    if len(ordenado) > 8:
        resto = sum(v for _, v in ordenado[8:])
        ordenado = ordenado[:8] + [("Otros", resto)]
    return dict(id="tipo_crema", titulo=f"Cremados por tipo{sufijo}",
                periodo=False, tipos=TIPOS_REPARTO, tipo_inicial="horizontales",
                categorico=True, categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Cremados", color=CLARO,
                             valores=[int(v) for _, v in ordenado])],
                eje_x="Tipo", eje_y="Cantidad")


def vista_servicios():
    cementerios = consultar(
        "SELECT cementerio, nombre FROM v_cementerios_activos ORDER BY nombre"
    )
    catalogo = {str(c["cementerio"]).strip(): c["nombre"] for c in cementerios}

    cem = request.args.get("cem", "")
    if cem not in catalogo:
        cem = None

    anios = _anios_disponibles()
    anio = request.args.get("anio", type=int)
    if anio not in anios:
        anio = None

    sufijo = f" · {catalogo[cem]}" if cem else ""
    graficas = [
        _datos_anio(cem, sufijo),
        _datos_mes(anio, cem, sufijo),
        _datos_cementerios(anio, catalogo, f" · {anio}" if anio else ""),
        _datos_tipo_crema(anio, cem, sufijo + (f" · {anio}" if anio else "")),
    ]
    return render_template(
        "servicios.html",
        totales=_totales(anio, cem), graficas=graficas,
        anios=anios, cementerios=cementerios, anio=anio, cem=cem,
    )