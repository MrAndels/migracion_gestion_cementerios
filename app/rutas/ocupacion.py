# app/rutas/ocupacion.py
from flask import render_template, request

from db import consultar, consultar_uno
from rutas.ingresos import _catalogo, _etiqueta, _norm

VERDE = "#0F6E56"

TIPOS_REPARTO = [("horizontales", "Barras horizontales"), ("barras", "Barras"),
                 ("dona", "Dona"), ("torta", "Torta")]


def _donde(cem):
    """WHERE con parámetros (nunca valores pegados al SQL)."""
    if cem:
        return "cementerio = %s", (cem,)
    return "1=1", ()


def _agrupar(filas, etiquetar, maximo):
    """Suma por nombre, ordena de mayor a menor y junta el resto en 'Otros'."""
    suma = {}
    for f in filas:
        nombre = etiquetar(f["valor"])
        suma[nombre] = suma.get(nombre, 0) + f["total"]
    ordenado = sorted(suma.items(), key=lambda x: x[1], reverse=True)
    if len(ordenado) > maximo:
        resto = sum(v for _, v in ordenado[maximo:])
        ordenado = ordenado[:maximo] + [("Otros", resto)]
    return ordenado


def _grafica(id_, titulo, campo, cem, etiquetar, eje_x, tipo_inicial,
             usar_filtro=True, maximo=8):
    donde, params = _donde(cem if usar_filtro else None)
    filas = consultar(
        f"SELECT {campo} AS valor, COUNT(*) AS total "
        f"FROM v_prop_unidades_activos WHERE {donde} GROUP BY {campo}",
        params,
    )
    ordenado = _agrupar(filas, etiquetar, maximo)
    return dict(id=id_, titulo=titulo, periodo=False, tipos=TIPOS_REPARTO,
                tipo_inicial=tipo_inicial, categorico=True,
                categorias=[k for k, _ in ordenado],
                series=[dict(nombre="Unidades", color=VERDE,
                             valores=[int(v) for _, v in ordenado])],
                eje_x=eje_x, eje_y="Unidades")


def _totales(cem):
    donde, params = _donde(cem)
    f = consultar_uno(
        "SELECT COUNT(*) AS unidades, "
        "COUNT(DISTINCT prop_lote_id) AS lotes, "
        "SUM(prop_lote_id IS NOT NULL) AS con_lote "
        f"FROM v_prop_unidades_activos WHERE {donde}", params
    )
    return dict(unidades=int(f["unidades"] or 0),
                lotes=int(f["lotes"] or 0),
                con_lote=int(f["con_lote"] or 0))


def vista_ocupacion():
    cementerios = consultar(
        "SELECT cementerio, nombre FROM v_cementerios_activos ORDER BY nombre"
    )
    nombres_cem = {_norm(c["cementerio"]): c["nombre"] for c in cementerios}

    cem = request.args.get("cem", "")
    if cem not in {str(c["cementerio"]) for c in cementerios}:
        cem = None

    estados = _catalogo("v_estado_boveda_activos", ("estado", "codigo", "id"))
    sectores = _catalogo("v_sector_activos", ("sector", "codigo", "id"))
    galerias = _catalogo("v_galerias_activos", ("galeria", "codigo", "id"))

    def etiqueta_estado(v):
        # Un estado vacío nunca debe confundirse con el código 0
        if v is None or str(v).strip() == "":
            return "Sin clasificar"
        return estados.get(_norm(v)) or "Sin clasificar"

    sufijo = f" · {nombres_cem.get(_norm(cem))}" if cem else ""
    graficas = [
        _grafica("estados", f"Unidades por estado{sufijo}", "estado", cem,
                 etiqueta_estado, "Estado", "horizontales"),
        _grafica("cementerios", "Unidades por cementerio", "cementerio", cem,
                 lambda v: _etiqueta(nombres_cem, v), "Cementerio", "barras",
                 usar_filtro=False),
        _grafica("sectores", f"Unidades por sector{sufijo}", "sector", cem,
                 lambda v: _etiqueta(sectores, v), "Sector", "barras"),
        _grafica("galerias", f"Unidades por galería{sufijo}", "galeria", cem,
                 lambda v: _etiqueta(galerias, v), "Galería", "horizontales",
                 maximo=10),
        _grafica("tipo_cons", f"Unidades por tipo de construcción{sufijo}",
                 "tipo_cons", cem,
                 lambda v: (str(v).strip() if v is not None and str(v).strip()
                            else "Sin dato"),
                 "Tipo", "horizontales"),
    ]
    return render_template("ocupacion.html", totales=_totales(cem),
                           graficas=graficas, cementerios=cementerios, cem=cem)