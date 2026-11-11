# app/rutas/dashboard.py
from flask import Blueprint, render_template
from flask_login import login_required
from rutas.servicios import vista_servicios
from rutas.ingresos import vista_ingresos
from rutas.ocupacion import vista_ocupacion
from rutas.personas import vista_personas

from db import consultar, consultar_uno

dashboard_bp = Blueprint("dashboard", __name__, url_prefix="/admin")

VERDE = "#0F6E56"
CLARO = "#5DCAA5"
GRIS = "#888780"

# Facturas válidas: anulada = 0 o vacío
VALIDAS = "COALESCE(anulada, 0) = 0"

# La gráfica de servicios por año muestra desde este año
ANIO_DESDE = 2000

TIPOS_TIEMPO = [("barras", "Barras"), ("lineas", "Líneas"),
                ("puntos", "Puntos"), ("area", "Área")]
TIPOS_SERVICIOS = [("barras", "Barras"), ("apiladas", "Barras apiladas"),
                   ("lineas", "Líneas"), ("puntos", "Puntos"), ("area", "Área")]
TIPOS_CEMENTERIOS = [("barras", "Barras"), ("apiladas", "Barras apiladas"),
                     ("horizontales", "Barras horizontales"), ("dona", "Dona")]
TIPOS_ESTADOS = [("horizontales", "Barras horizontales"), ("barras", "Barras"),
                 ("dona", "Dona"), ("torta", "Torta")]


def totales():
    return consultar_uno(
        f"""
        SELECT
            (SELECT COUNT(*) FROM v_inhumados_activos)     AS inhumados,
            (SELECT COUNT(*) FROM v_cremados_activos)      AS cremados,
            (SELECT COUNT(*) FROM v_exhumados_activos)     AS exhumados,
            (SELECT COUNT(*) FROM v_prop_unidades_activos) AS unidades,
            (SELECT COUNT(DISTINCT prop_lote_id)
               FROM v_prop_unidades_activos
              WHERE prop_lote_id IS NOT NULL)              AS propietarios,
            (SELECT COUNT(*) FROM v_factura_activos
              WHERE {VALIDAS})                             AS facturas
        """
    )


# ---------- Datos de las gráficas (el navegador las dibuja) ----------

def datos_servicios_anio():
    fuentes = [
        ("Inhumados", "v_inhumados_activos", "fecha_inh", VERDE),
        ("Cremados", "v_cremados_activos", "fecha_cre", CLARO),
        ("Exhumados", "v_exhumados_activos", "fecha_exh", GRIS),
    ]
    por_serie = []
    for nombre, vista, campo, color in fuentes:
        filas = consultar(
            f"SELECT YEAR({campo}) AS anio, COUNT(*) AS n "
            f"FROM {vista} "
            f"WHERE {campo} IS NOT NULL AND YEAR({campo}) >= {ANIO_DESDE} "
            f"GROUP BY anio ORDER BY anio"
        )
        por_serie.append((nombre, color, {f["anio"]: f["n"] for f in filas}))

    todos = [a for _, _, d in por_serie for a in d]
    anios = list(range(min(todos), max(todos) + 1))
    series = [dict(nombre=n, color=c, valores=[int(d.get(a, 0)) for a in anios])
              for n, c, d in por_serie]
    return dict(id="servicios",
                titulo=f"Servicios por año (desde {ANIO_DESDE})",
                periodo=True, tipos=TIPOS_SERVICIOS, tipo_inicial="barras",
                categorico=False, categorias=anios, series=series,
                eje_x="Año", eje_y="Cantidad")


def datos_facturacion_anio():
    filas = consultar(
        "SELECT YEAR(fecha) AS anio, SUM(valor) AS total "
        "FROM v_factura_activos "
        f"WHERE fecha IS NOT NULL AND {VALIDAS} "
        "GROUP BY anio ORDER BY anio"
    )
    anios = [f["anio"] for f in filas]
    valores = [round(float(f["total"] or 0) / 1_000_000, 1) for f in filas]
    return dict(id="facturacion", titulo="Facturación por año (facturas válidas)",
                periodo=True, tipos=TIPOS_TIEMPO, tipo_inicial="barras",
                categorico=False, categorias=anios,
                series=[dict(nombre="Facturación", color=VERDE, valores=valores)],
                eje_x="Año", eje_y="Millones de pesos")


def datos_cementerios():
    filas = consultar(
        """
        SELECT COALESCE(c.nombre, t.cementerio) AS nombre_cem,
               t.tipo, COUNT(*) AS n
        FROM (
            SELECT cementerio, 'Inhumados' AS tipo FROM v_inhumados_activos
            UNION ALL
            SELECT cementerio, 'Cremados'  AS tipo FROM v_cremados_activos
        ) t
        LEFT JOIN v_cementerios_activos c ON c.cementerio = t.cementerio
        GROUP BY COALESCE(c.nombre, t.cementerio), t.tipo
        """
    )
    suma = {}
    for f in filas:
        nombre = str(f["nombre_cem"] or "Sin dato")
        suma[nombre] = suma.get(nombre, 0) + f["n"]
    nombres = sorted(suma, key=suma.get, reverse=True)

    series = []
    for tipo, color in (("Inhumados", VERDE), ("Cremados", CLARO)):
        datos = {str(f["nombre_cem"] or "Sin dato"): f["n"]
                 for f in filas if f["tipo"] == tipo}
        series.append(dict(nombre=tipo, color=color,
                           valores=[int(datos.get(n, 0)) for n in nombres]))
    return dict(id="cementerios", titulo="Servicios por cementerio",
                periodo=False, tipos=TIPOS_CEMENTERIOS, tipo_inicial="barras",
                categorico=True, categorias=nombres, series=series,
                eje_x="Cementerio", eje_y="Cantidad")


def datos_estados():
    cuentas = consultar(
        "SELECT estado, COUNT(*) AS n "
        "FROM v_prop_unidades_activos GROUP BY estado"
    )
    catalogo = {
        str(f["estado"]).strip(): f["nombre"]
        for f in consultar("SELECT estado, nombre FROM v_estado_boveda_activos")
    }
    suma = {}
    for f in cuentas:
        clave = "" if f["estado"] is None else str(f["estado"]).strip()
        nombre = catalogo.get(clave) if clave else None
        nombre = nombre or "Sin clasificar"
        suma[nombre] = suma.get(nombre, 0) + f["n"]

    ordenado = sorted(suma.items(), key=lambda x: x[1], reverse=True)
    return dict(id="estados", titulo="Unidades por estado", periodo=False,
                tipos=TIPOS_ESTADOS, tipo_inicial="horizontales",
                categorico=True, categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Unidades", color=VERDE,
                             valores=[int(v) for _, v in ordenado])],
                eje_x="Estado", eje_y="Cantidad")


# ---------- Rutas ----------

@dashboard_bp.route("/dashboard")
@login_required
def dashboard():
    t = totales()
    ingresos = consultar_uno(
        f"SELECT COALESCE(SUM(valor), 0) AS total FROM v_factura_activos "
        f"WHERE {VALIDAS}"
    )["total"]

    cuadros = [
        dict(titulo="Servicios", endpoint="dashboard.servicios",
             cifra=f"{t['inhumados'] + t['cremados'] + t['exhumados']:,}",
             detalle="Inhumados, cremados y exhumados"),
        dict(titulo="Ingresos", endpoint="dashboard.ingresos",
             cifra=f"$ {float(ingresos):,.0f}",
             detalle="Total facturado (sin anuladas)"),
        dict(titulo="Ocupación", endpoint="dashboard.ocupacion",
             cifra=f"{t['unidades']:,}",
             detalle="Unidades registradas"),
        dict(titulo="Personas", endpoint="dashboard.personas",
             cifra=f"{t['inhumados'] + t['cremados']:,}",
             detalle="Perfil de las personas atendidas"),
    ]
    graficas = [datos_servicios_anio(), datos_facturacion_anio(),
                datos_cementerios(), datos_estados()]
    return render_template("dashboard.html", totales=t, cuadros=cuadros,
                           graficas=graficas)


def _proximamente(titulo):
    return render_template("proximamente.html", titulo=titulo)


@dashboard_bp.route("/servicios")
@login_required
def servicios():
    return vista_servicios()


@dashboard_bp.route("/ingresos")
@login_required
def ingresos():
    return vista_ingresos()


@dashboard_bp.route("/ocupacion")
@login_required
def ocupacion():
    return vista_ocupacion()


@dashboard_bp.route("/personas")
@login_required
def personas():
    return vista_personas()


@dashboard_bp.route("/datos")
@login_required
def datos():
    return _proximamente("Datos")