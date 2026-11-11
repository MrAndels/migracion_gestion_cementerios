# app/rutas/personas.py
from flask import render_template, request

from db import consultar
from rutas.ingresos import _catalogo, _etiqueta, _norm, _donde as _donde_fact
from rutas.ocupacion import _agrupar
from rutas.servicios import _anios_disponibles

VERDE = "#0F6E56"
CLARO = "#5DCAA5"

RANGOS = ["0–17", "18–39", "40–59", "60–79", "80 o más", "Sin dato"]

TIPOS_REPARTO = [("dona", "Dona"), ("torta", "Torta"),
                 ("barras", "Barras"), ("horizontales", "Barras horizontales")]
TIPOS_EDAD = [("barras", "Barras"), ("apiladas", "Barras apiladas"),
              ("lineas", "Líneas"), ("puntos", "Puntos"), ("area", "Área")]
TIPOS_TOP = [("horizontales", "Barras horizontales"), ("barras", "Barras"),
             ("dona", "Dona"), ("torta", "Torta")]


def _edad(v):
    """Edad como número entero, o None si el dato no sirve."""
    try:
        n = int(float(str(v).strip()))
    except (ValueError, TypeError):
        return None
    return n if 0 <= n <= 110 else None


def _rango(n):
    if n is None:
        return "Sin dato"
    if n < 18:
        return "0–17"
    if n < 40:
        return "18–39"
    if n < 60:
        return "40–59"
    if n < 80:
        return "60–79"
    return "80 o más"


def _sexo(v):
    s = str(v or "").strip().upper()
    if not s:
        return "Sin dato"
    if s in ("M", "MASCULINO", "H", "HOMBRE"):
        return "Masculino"
    if s in ("F", "FEMENINO", "MUJER"):
        return "Femenino"
    return s


def _filas(anio, cem):
    """Una fila por combinación sexo/edad/causa/tipo, ya contada en MySQL."""
    cond, params = ["1=1"], []
    if anio is not None:
        cond.append("YEAR(fecha) = %s")
        params.append(anio)
    if cem:
        cond.append("cementerio = %s")
        params.append(cem)
    return consultar(
        f"""
        SELECT sexo, edad, causa_muer, tipo, COUNT(*) AS n
        FROM (
            SELECT sexo, edad, causa_muer, cementerio,
                   fecha_inh AS fecha, 'Inhumados' AS tipo
            FROM v_inhumados_activos
            UNION ALL
            SELECT sexo, edad, causa_muer, cementerio,
                   fecha_cre AS fecha, 'Cremados' AS tipo
            FROM v_cremados_activos
        ) t
        WHERE {" AND ".join(cond)}
        GROUP BY sexo, edad, causa_muer, tipo
        """,
        tuple(params),
    )


def _ordenar(suma, maximo=None):
    ordenado = sorted(suma.items(), key=lambda x: x[1], reverse=True)
    if maximo and len(ordenado) > maximo:
        resto = sum(v for _, v in ordenado[maximo:])
        ordenado = ordenado[:maximo] + [("Otros", resto)]
    return ordenado


def vista_personas():
    cementerios = consultar(
        "SELECT cementerio, nombre FROM v_cementerios_activos ORDER BY nombre"
    )
    nombres_cem = {_norm(c["cementerio"]): c["nombre"] for c in cementerios}
    cem = request.args.get("cem", "")
    if cem not in {str(c["cementerio"]) for c in cementerios}:
        cem = None

    anios = _anios_disponibles()
    anio = request.args.get("anio", type=int)
    if anio not in anios:
        anio = None

    causas = _catalogo("v_causa_muerte_activos",
                       ("causa_muer", "causa", "codigo", "id"))
    # La factura guarda el NIT de la funeraria, no su código ni su id
    funerarias = _catalogo("v_funerarias_activos", ("nit",))

    filas = _filas(anio, cem)

    por_sexo, por_causa = {}, {}
    por_rango = {"Inhumados": {r: 0 for r in RANGOS},
                 "Cremados": {r: 0 for r in RANGOS}}
    n_tipo = {"Inhumados": 0, "Cremados": 0}
    suma_edad, n_edad = 0, 0

    for f in filas:
        n = int(f["n"])
        n_tipo[f["tipo"]] += n
        s = _sexo(f["sexo"])
        por_sexo[s] = por_sexo.get(s, 0) + n
        c = _etiqueta(causas, f["causa_muer"])
        por_causa[c] = por_causa.get(c, 0) + n
        e = _edad(f["edad"])
        por_rango[f["tipo"]][_rango(e)] += n
        if e is not None:
            suma_edad += e * n
            n_edad += n

    # ----- Top funerarias (facturas válidas) -----
    donde, params = _donde_fact(anio=anio, cem=cem)
    f_fun = consultar(
        f"SELECT funeraria AS valor, COUNT(*) AS total "
        f"FROM v_factura_activos WHERE {donde} GROUP BY funeraria", params
    )
    top = _agrupar(f_fun, lambda v: _etiqueta(funerarias, v), 100000)
    top = [x for x in top if x[0] != "Sin dato"]

    s_cem = f" · {nombres_cem.get(_norm(cem))}" if cem else ""
    s_anio = f" · {anio}" if anio else ""
    sufijo = s_cem + s_anio

    sexo_ord = _ordenar(por_sexo)
    causa_ord = _ordenar(por_causa, 8)

    graficas = [
        dict(id="sexo", titulo=f"Personas por sexo{sufijo}", periodo=False,
             tipos=TIPOS_REPARTO, tipo_inicial="dona", categorico=True,
             categorias=[k for k, _ in sexo_ord],
             series=[dict(nombre="Personas", color=VERDE,
                          valores=[v for _, v in sexo_ord])],
             eje_x="Sexo", eje_y="Personas"),
        dict(id="edad", titulo=f"Personas por rango de edad{sufijo}",
             periodo=False, tipos=TIPOS_EDAD, tipo_inicial="barras",
             categorico=True, categorias=RANGOS,
             series=[dict(nombre="Inhumados", color=VERDE,
                          valores=[por_rango["Inhumados"][r] for r in RANGOS]),
                     dict(nombre="Cremados", color=CLARO,
                          valores=[por_rango["Cremados"][r] for r in RANGOS])],
             eje_x="Edad", eje_y="Personas"),
        dict(id="causas", titulo=f"Causas de muerte{sufijo}", periodo=False,
             tipos=TIPOS_TOP, tipo_inicial="horizontales", categorico=True,
             categorias=[k for k, _ in causa_ord],
             series=[dict(nombre="Personas", color=VERDE,
                          valores=[v for _, v in causa_ord])],
             eje_x="Causa", eje_y="Personas"),
        dict(id="funerarias", titulo=f"Funerarias por facturas{sufijo}",
             periodo=False, tipos=TIPOS_TOP, tipo_inicial="horizontales",
             categorico=True, categorias=[k for k, _ in top],
             series=[dict(nombre="Facturas", color=CLARO,
                          valores=[int(v) for _, v in top])],
             eje_x="Funeraria", eje_y="Facturas",
             limites=[10, 25, 50, 0], limite_inicial=10, ancha=True),
    ]

    totales = dict(
        personas=n_tipo["Inhumados"] + n_tipo["Cremados"],
        inhumados=n_tipo["Inhumados"],
        cremados=n_tipo["Cremados"],
        edad_promedio=(suma_edad / n_edad) if n_edad else 0,
    )
    return render_template("personas.html", totales=totales, graficas=graficas,
                           anios=anios, cementerios=cementerios,
                           anio=anio, cem=cem)