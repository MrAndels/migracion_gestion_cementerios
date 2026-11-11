# app/rutas/ingresos.py
from flask import render_template, request

from db import consultar, consultar_uno

VERDE = "#0F6E56"
CLARO = "#5DCAA5"

MESES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
         "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

TIPOS_ANIO = [("barras", "Barras"), ("lineas", "Líneas"),
              ("puntos", "Puntos"), ("area", "Área")]
TIPOS_MES = [("lineas", "Líneas"), ("barras", "Barras"),
             ("puntos", "Puntos"), ("area", "Área")]
TIPOS_REPARTO = [("horizontales", "Barras horizontales"), ("barras", "Barras"),
                 ("dona", "Dona"), ("torta", "Torta")]
TIPOS_TOP = [("horizontales", "Barras horizontales"), ("barras", "Barras")]


def _norm(x):
    """Normaliza un código: '02' y '2' cuentan como el mismo."""
    s = str(x).strip()
    return (s.lstrip("0") or "0") if s.isdigit() else s


def _millones(v):
    return round(float(v or 0) / 1_000_000, 1)


def _catalogo(vista, claves):
    """Lee una tabla de nombres y devuelve {código: nombre}."""
    filas = consultar(f"SELECT * FROM {vista}")
    if not filas:
        return {}
    clave = next((k for k in claves if k in filas[0]), "id")
    mapa = {}
    for f in filas:
        cod = f.get(clave)
        nombre = next((f[k] for k in ("nombre", "descripcion", "detalle")
                       if f.get(k)), None)
        mapa[_norm(cod)] = str(nombre or cod).strip()
    return mapa


def _etiqueta(mapa, cod):
    if cod is None or str(cod).strip() == "":
        return "Sin dato"
    return mapa.get(_norm(cod)) or str(cod).strip()


def _donde(pref="", anio=None, cem=None, validas=True):
    """WHERE sobre facturas, con parámetros (nunca valores pegados al SQL)."""
    p = pref + "." if pref else ""
    cond, params = [], []
    if validas:
        cond.append(f"COALESCE({p}anulada, 0) = 0")
    if anio is not None:
        cond.append(f"YEAR({p}fecha) = %s")
        params.append(anio)
    if cem:
        cond.append(f"{p}cementerio = %s")
        params.append(cem)
    return (" AND ".join(cond) or "1=1"), tuple(params)


def _reparto(filas, mapa, campo, maximo=8):
    """Agrupa por nombre, ordena de mayor a menor y junta el resto en 'Otros'."""
    suma = {}
    for f in filas:
        nombre = _etiqueta(mapa, f[campo])
        suma[nombre] = suma.get(nombre, 0) + float(f["total"] or 0)
    ordenado = sorted(suma.items(), key=lambda x: x[1], reverse=True)
    if len(ordenado) > maximo:
        resto = sum(v for _, v in ordenado[maximo:])
        ordenado = ordenado[:maximo] + [("Otros", resto)]
    return ordenado


# ---------- Totales ----------

def _totales(anio, cem):
    donde, params = _donde(anio=anio, cem=cem)
    validas = consultar_uno(
        f"SELECT COUNT(*) AS n, COALESCE(SUM(valor), 0) AS total "
        f"FROM v_factura_activos WHERE {donde}", params
    )
    donde_a, params_a = _donde(anio=anio, cem=cem, validas=False)
    anuladas = consultar_uno(
        f"SELECT COUNT(*) AS n, COALESCE(SUM(valor), 0) AS total "
        f"FROM v_factura_activos WHERE {donde_a} AND COALESCE(anulada, 0) = 1",
        params_a,
    )
    if anio is not None:
        consig = consultar_uno(
            "SELECT COALESCE(SUM(valor), 0) AS total "
            "FROM v_consignaciones_activos WHERE YEAR(fecha) = %s", (anio,)
        )
    else:
        consig = consultar_uno(
            "SELECT COALESCE(SUM(valor), 0) AS total FROM v_consignaciones_activos"
        )
    n = validas["n"]
    total = float(validas["total"])
    return dict(
        facturado=total / 1_000_000,
        facturas=n,
        promedio=(total / n) if n else 0,
        consignado=float(consig["total"]) / 1_000_000,
        anulado=float(anuladas["total"]) / 1_000_000,
        n_anuladas=anuladas["n"],
    )


def _anios_disponibles():
    filas = consultar(
        "SELECT DISTINCT YEAR(fecha) AS a FROM v_factura_activos "
        "WHERE fecha IS NOT NULL AND COALESCE(anulada, 0) = 0 ORDER BY a DESC"
    )
    return [f["a"] for f in filas]


# ---------- Gráficas ----------

def _datos_anio(cem, sufijo):
    donde, params = _donde(cem=cem)
    filas = consultar(
        f"SELECT YEAR(fecha) AS anio, SUM(valor) AS total "
        f"FROM v_factura_activos WHERE fecha IS NOT NULL AND {donde} "
        f"GROUP BY anio ORDER BY anio", params
    )
    return dict(id="anio", titulo=f"Facturación por año{sufijo}", periodo=True,
                tipos=TIPOS_ANIO, tipo_inicial="barras", categorico=False,
                categorias=[f["anio"] for f in filas],
                series=[dict(nombre="Facturación", color=VERDE,
                             valores=[_millones(f["total"]) for f in filas])],
                eje_x="Año", eje_y="Millones de pesos")


def _datos_mes(anio, cem, sufijo):
    donde, params = _donde(anio=anio, cem=cem)
    filas = consultar(
        f"SELECT MONTH(fecha) AS mes, SUM(valor) AS total "
        f"FROM v_factura_activos WHERE fecha IS NOT NULL AND {donde} "
        f"GROUP BY mes", params
    )
    por_mes = {f["mes"]: f["total"] for f in filas}
    cuando = str(anio) if anio else "todos los años"
    return dict(id="mes", titulo=f"Facturación por mes ({cuando}){sufijo}",
                periodo=False, tipos=TIPOS_MES, tipo_inicial="lineas",
                categorico=True, categorias=MESES,
                series=[dict(nombre="Facturación", color=VERDE,
                             valores=[_millones(por_mes.get(m)) for m in range(1, 13)])],
                eje_x="Mes", eje_y="Millones de pesos")


def _datos_forma_pago(anio, cem, formas, sufijo):
    donde, params = _donde(anio=anio, cem=cem)
    filas = consultar(
        f"SELECT forma_pago, SUM(valor) AS total FROM v_factura_activos "
        f"WHERE {donde} GROUP BY forma_pago", params
    )
    ordenado = _reparto(filas, formas, "forma_pago")
    return dict(id="forma_pago", titulo=f"Facturación por forma de pago{sufijo}",
                periodo=False, tipos=TIPOS_REPARTO, tipo_inicial="dona",
                categorico=True, categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Facturación", color=VERDE,
                             valores=[_millones(v) for _, v in ordenado])],
                eje_x="Forma de pago", eje_y="Millones de pesos")


def _datos_bancos(anio, bancos, sufijo):
    if anio is not None:
        filas = consultar(
            "SELECT banco, SUM(valor) AS total FROM v_consignaciones_activos "
            "WHERE YEAR(fecha) = %s GROUP BY banco", (anio,)
        )
    else:
        filas = consultar(
            "SELECT banco, SUM(valor) AS total FROM v_consignaciones_activos "
            "GROUP BY banco"
        )
    ordenado = _reparto(filas, bancos, "banco")
    return dict(id="bancos", titulo=f"Consignaciones por banco{sufijo}",
                periodo=False, tipos=TIPOS_REPARTO, tipo_inicial="horizontales",
                categorico=True, categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Consignado", color=CLARO,
                             valores=[_millones(v) for _, v in ordenado])],
                eje_x="Banco", eje_y="Millones de pesos")


def _datos_top_servicios(anio, cem, items, sufijo):
    donde, params = _donde(pref="f", anio=anio, cem=cem)
    filas = consultar(
        f"SELECT d.servicio AS servicio, SUM(d.valor) AS total "
        f"FROM v_detalle_fact_activos d "
        f"JOIN v_factura_activos f ON f.id = d.factura_id "
        f"WHERE {donde} GROUP BY d.servicio", params
    )
    ordenado = _reparto(filas, items, "servicio", maximo=10)
    ordenado = [x for x in ordenado if x[0] != "Otros"]
    return dict(id="top", titulo=f"Top 10 servicios facturados{sufijo}",
                periodo=False, tipos=TIPOS_TOP, tipo_inicial="horizontales",
                categorico=True, categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Facturado", color=VERDE,
                             valores=[_millones(v) for _, v in ordenado])],
                eje_x="Servicio", eje_y="Millones de pesos")


# ---------- Vista ----------

def vista_ingresos():
    cementerios = consultar(
        "SELECT cementerio, nombre FROM v_cementerios_activos ORDER BY nombre"
    )
    nombres_cem = {str(c["cementerio"]): c["nombre"] for c in cementerios}
    cem = request.args.get("cem", "")
    if cem not in nombres_cem:
        cem = None

    anios = _anios_disponibles()
    anio = request.args.get("anio", type=int)
    if anio not in anios:
        anio = None

    bancos = _catalogo("v_bancos_activos", ("banco", "codigo", "id"))
    formas = _catalogo("v_forma_pago_activos", ("forma_pago", "forma", "codigo", "id"))
    items = _catalogo("v_items_activos", ("item", "servicio", "codigo", "id"))

    s_cem = f" · {nombres_cem[cem]}" if cem else ""
    s_anio = f" · {anio}" if anio else ""

    graficas = [
        _datos_anio(cem, s_cem),
        _datos_mes(anio, cem, s_cem),
        _datos_forma_pago(anio, cem, formas, s_cem + s_anio),
        _datos_bancos(anio, bancos, s_anio),
        _datos_top_servicios(anio, cem, items, s_cem + s_anio),
    ]
    return render_template(
        "ingresos.html", totales=_totales(anio, cem), graficas=graficas,
        anios=anios, cementerios=cementerios, anio=anio, cem=cem,
    )