# app/rutas/admin.py
import math
import time
from datetime import date, datetime
from decimal import Decimal, InvalidOperation

import pymysql
from flask import (Blueprint, abort, flash, redirect, render_template,
                   request, url_for)
from flask_login import current_user, login_required

from db import consultar, consultar_uno, ejecutar

admin_bp = Blueprint("admin", __name__, url_prefix="/admin/datos")

GRUPOS = [
    ("Servicios", ["inhumados", "inhumados_nn", "cremados", "exhumados",
                   "esqueletos"]),
    ("Propietarios y unidades", ["prop_lotes", "prop_unidades", "pabellon",
                                 "galerias", "sector"]),
    ("Facturación", ["factura", "detalle_fact", "consignaciones", "efectivo",
                     "devoluciones", "conciliacion"]),
    ("Catálogos", ["bancos", "cementerios", "funerarias", "oficinas", "items",
                   "forma_pago", "tipo_serv", "tipo_id", "tipo_usuario",
                   "parentesco", "causa_muerte", "estado_boveda", "lugar_inh"]),
    ("Otras", ["inventario", "rc", "servicios"]),
]
TABLAS = {t for _, ts in GRUPOS for t in ts}

# Tablas de dinero: se pueden ver, pero no modificar
SOLO_LECTURA = {"factura", "detalle_fact", "consignaciones", "efectivo",
                "devoluciones", "conciliacion"}

# Columnas que terminan en _id pero son datos reales (no enlaces de la migración)
EXCEPCIONES_ID = {"tipo_id"}

POR_PAGINA = 25
ENTEROS = {"tinyint", "smallint", "mediumint", "int", "bigint"}
DECIMALES = {"decimal", "float", "double"}
FECHAS = {"date"}
FECHAHORA = {"datetime", "timestamp"}
TEXTOS_LARGOS = {"text", "tinytext", "mediumtext", "longtext"}


# ---------- Utilidades ----------

def valida(tabla):
    if tabla not in TABLAS:
        abort(404)
    return tabla


def escribible(tabla):
    valida(tabla)
    if tabla in SOLO_LECTURA:
        abort(403)
    return tabla


def es_enlace(nombre):
    return nombre.endswith("_id") and nombre not in EXCEPCIONES_ID


_cache_cols = {}


def columnas(tabla):
    """Columnas de una tabla, leídas de information_schema (y guardadas)."""
    if tabla not in _cache_cols:
        filas = consultar(
            "SELECT column_name AS nombre, data_type AS tipo, "
            "is_nullable AS nulo, character_maximum_length AS largo, "
            "column_default AS defecto "
            "FROM information_schema.columns "
            "WHERE table_schema = DATABASE() AND table_name = %s "
            "ORDER BY ordinal_position", (tabla,)
        )
        cols = []
        for f in filas:
            tipo = str(f["tipo"]).lower()
            nulo = f["nulo"] == "YES"
            cols.append(dict(
                nombre=f["nombre"], tipo=tipo, nulo=nulo, largo=f["largo"],
                defecto=f["defecto"],
                obligatorio=(not nulo and f["defecto"] is None and
                             tipo in ENTEROS | DECIMALES | FECHAS | FECHAHORA),
            ))
        _cache_cols[tabla] = cols
    return _cache_cols[tabla]


def campos_editables(cols):
    return [c for c in cols
            if c["nombre"] not in ("id", "borrado") and not es_enlace(c["nombre"])]


_cache_conteos = {"hasta": 0, "datos": {}}


def conteos():
    if time.time() > _cache_conteos["hasta"]:
        datos = {}
        for t in TABLAS:
            datos[t] = consultar_uno(
                f"SELECT COUNT(*) AS n FROM `{t}` WHERE borrado = 0")["n"]
        _cache_conteos.update(hasta=time.time() + 60, datos=datos)
    return _cache_conteos["datos"]


def invalidar():
    _cache_conteos["hasta"] = 0


def texto(v):
    if v is None:
        return None
    if isinstance(v, datetime):
        return v.strftime("%Y-%m-%d %H:%M:%S")
    return str(v)


def mostrar(v):
    s = texto(v) or ""
    return s if len(s) <= 40 else s[:40] + "…"


def para_campo(v):
    if v is None:
        return ""
    if isinstance(v, datetime):
        return v.strftime("%Y-%m-%dT%H:%M")
    if isinstance(v, date):
        return v.isoformat()
    return str(v)


def iguales(viejo, nuevo):
    if viejo is None or nuevo is None:
        return viejo is None and nuevo is None
    if isinstance(viejo, (int, float, Decimal)):
        try:
            return Decimal(str(viejo)) == Decimal(str(nuevo))
        except InvalidOperation:
            return False
    return texto(viejo) == texto(nuevo)


def convertir(col, crudo):
    """Devuelve (usar, valor). Lanza ValueError con un mensaje claro."""
    t = (crudo or "").strip()
    tipo = col["tipo"]
    if t == "":
        if col["nulo"]:
            return True, None
        if tipo in ENTEROS | DECIMALES | FECHAS | FECHAHORA:
            return False, None
        return True, ""
    if tipo in ENTEROS:
        try:
            return True, int(t)
        except ValueError:
            raise ValueError("debe ser un número entero")
    if tipo in DECIMALES:
        try:
            return True, Decimal(t.replace(",", "."))
        except InvalidOperation:
            raise ValueError("debe ser un número")
    if tipo in FECHAS:
        try:
            datetime.strptime(t, "%Y-%m-%d")
        except ValueError:
            raise ValueError("fecha no válida")
        return True, t
    if tipo in FECHAHORA:
        t = t.replace("T", " ")
        if len(t) == 16:
            t += ":00"
        try:
            datetime.strptime(t, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            raise ValueError("fecha y hora no válidas")
        return True, t
    if col["largo"] and len(t) > col["largo"]:
        raise ValueError(f"máximo {col['largo']} caracteres")
    return True, t


def leer_formulario(editables, insertar):
    datos, errores = {}, []
    for c in editables:
        try:
            usar, valor = convertir(c, request.form.get(c["nombre"], ""))
        except ValueError as e:
            errores.append(f"{c['nombre']}: {e}")
            continue
        if usar:
            datos[c["nombre"]] = valor
        elif insertar and c["obligatorio"]:
            errores.append(f"{c['nombre']}: es obligatorio.")
    return datos, errores


def registrar(accion, tabla, registro_id, detalle=None):
    ejecutar(
        "INSERT INTO log_cambios (usuario, accion, tabla, registro_id, detalle, ip) "
        "VALUES (%s, %s, %s, %s, %s, %s)",
        (current_user.id, accion, tabla, registro_id,
         detalle[:4000] if detalle else None, request.remote_addr),
    )


def obtener(tabla, id):
    fila = consultar_uno(f"SELECT * FROM `{tabla}` WHERE id = %s", (id,))
    if not fila:
        abort(404)
    return fila


# ---------- Rutas ----------

@admin_bp.route("/")
@login_required
def tablas():
    return render_template("admin/tablas.html", grupos=GRUPOS,
                           conteos=conteos(), solo_lectura=SOLO_LECTURA)


@admin_bp.route("/historial")
@login_required
def historial():
    tabla = request.args.get("tabla", "")
    if tabla in TABLAS:
        filas = consultar(
            "SELECT * FROM log_cambios WHERE tabla = %s "
            "ORDER BY id DESC LIMIT 300", (tabla,))
    else:
        tabla = ""
        filas = consultar("SELECT * FROM log_cambios ORDER BY id DESC LIMIT 300")
    return render_template("admin/historial.html", filas=filas, tabla=tabla,
                           tablas=sorted(TABLAS))


@admin_bp.route("/<tabla>")
@login_required
def lista(tabla):
    valida(tabla)
    cols = columnas(tabla)
    visibles = [c for c in cols
                if c["nombre"] not in ("id", "borrado")
                and not es_enlace(c["nombre"])][:7]

    q = request.args.get("q", "").strip()
    eliminados = request.args.get("eliminados") == "1"
    pagina = max(request.args.get("pagina", 1, type=int), 1)

    cond, params = ["borrado = %s"], [1 if eliminados else 0]
    if q:
        partes = []
        for c in [c for c in cols if c["tipo"] in ("varchar", "char")][:6]:
            partes.append(f"`{c['nombre']}` LIKE %s")
            params.append(f"%{q}%")
        if q.isdigit():
            partes.append("id = %s")
            params.append(int(q))
        if partes:
            cond.append("(" + " OR ".join(partes) + ")")
    donde = " AND ".join(cond)

    total = consultar_uno(
        f"SELECT COUNT(*) AS n FROM `{tabla}` WHERE {donde}", tuple(params))["n"]
    paginas = max(math.ceil(total / POR_PAGINA), 1)
    pagina = min(pagina, paginas)

    seleccion = ", ".join(f"`{n}`" for n in ["id"] + [c["nombre"] for c in visibles])
    registros = consultar(
        f"SELECT {seleccion} FROM `{tabla}` WHERE {donde} "
        f"ORDER BY id DESC LIMIT %s OFFSET %s",
        tuple(params) + (POR_PAGINA, (pagina - 1) * POR_PAGINA),
    )
    filas = [(r["id"], [mostrar(r[c["nombre"]]) for c in visibles])
             for r in registros]

    return render_template(
        "admin/lista.html", tabla=tabla, visibles=visibles, filas=filas,
        q=q, eliminados=eliminados, total=total, pagina=pagina,
        paginas=paginas, editable=tabla not in SOLO_LECTURA)


@admin_bp.route("/<tabla>/nuevo", methods=["GET", "POST"])
@login_required
def nuevo(tabla):
    escribible(tabla)
    editables = campos_editables(columnas(tabla))
    valores = {}

    if request.method == "POST":
        valores = {c["nombre"]: request.form.get(c["nombre"], "") for c in editables}
        datos, errores = leer_formulario(editables, insertar=True)
        if not errores:
            try:
                if datos:
                    nombres = ", ".join(f"`{k}`" for k in datos)
                    marcas = ", ".join(["%s"] * len(datos))
                    nuevo_id = ejecutar(
                        f"INSERT INTO `{tabla}` ({nombres}) VALUES ({marcas})",
                        tuple(datos.values()))
                else:
                    nuevo_id = ejecutar(f"INSERT INTO `{tabla}` () VALUES ()")
                detalle = "; ".join(f"{k}={texto(v)}" for k, v in datos.items())
                registrar("crear", tabla, nuevo_id, detalle)
                invalidar()
                flash("Registro creado.", "ok")
                return redirect(url_for("admin.ver", tabla=tabla, id=nuevo_id))
            except pymysql.MySQLError as e:
                errores.append(f"No se pudo guardar: {e}")
        for e in errores:
            flash(e)

    return render_template("admin/formulario.html", tabla=tabla, modo="nuevo",
                           titulo="Nuevo registro", campos=editables,
                           valores=valores, id=None, eliminado=False)


@admin_bp.route("/<tabla>/<int:id>")
@login_required
def ver(tabla, id):
    valida(tabla)
    fila = obtener(tabla, id)
    campos = [c for c in columnas(tabla) if c["nombre"] != "borrado"]
    valores = {c["nombre"]: para_campo(fila[c["nombre"]]) for c in campos}
    return render_template("admin/formulario.html", tabla=tabla, modo="ver",
                           titulo=f"Registro #{id}", campos=campos,
                           valores=valores, id=id,
                           eliminado=bool(fila["borrado"]),
                           editable=tabla not in SOLO_LECTURA)


@admin_bp.route("/<tabla>/<int:id>/editar", methods=["GET", "POST"])
@login_required
def editar(tabla, id):
    escribible(tabla)
    fila = obtener(tabla, id)
    if fila["borrado"]:
        flash("Este registro está eliminado. Restáuralo para poder editarlo.")
        return redirect(url_for("admin.ver", tabla=tabla, id=id))

    editables = campos_editables(columnas(tabla))
    valores = {c["nombre"]: para_campo(fila[c["nombre"]]) for c in editables}

    if request.method == "POST":
        valores = {c["nombre"]: request.form.get(c["nombre"], "") for c in editables}
        datos, errores = leer_formulario(editables, insertar=False)
        if not errores:
            cambios = {k: v for k, v in datos.items()
                       if not iguales(fila.get(k), v)}
            if not cambios:
                flash("No hay cambios que guardar.")
                return redirect(url_for("admin.ver", tabla=tabla, id=id))
            try:
                sets = ", ".join(f"`{k}` = %s" for k in cambios)
                ejecutar(
                    f"UPDATE `{tabla}` SET {sets} WHERE id = %s AND borrado = 0",
                    tuple(cambios.values()) + (id,))
                detalle = "; ".join(
                    f"{k}: {texto(fila.get(k))} → {texto(v)}"
                    for k, v in cambios.items())
                registrar("modificar", tabla, id, detalle)
                flash("Cambios guardados.", "ok")
                return redirect(url_for("admin.ver", tabla=tabla, id=id))
            except pymysql.MySQLError as e:
                errores.append(f"No se pudo guardar: {e}")
        for e in errores:
            flash(e)

    return render_template("admin/formulario.html", tabla=tabla, modo="editar",
                           titulo=f"Editar registro #{id}", campos=editables,
                           valores=valores, id=id, eliminado=False)


@admin_bp.route("/<tabla>/<int:id>/eliminar", methods=["POST"])
@login_required
def eliminar(tabla, id):
    escribible(tabla)
    obtener(tabla, id)
    ejecutar(f"UPDATE `{tabla}` SET borrado = 1 WHERE id = %s AND borrado = 0", (id,))
    registrar("eliminar", tabla, id, "borrado = 1")
    invalidar()
    flash("Registro eliminado (marcado como borrado).", "ok")
    return redirect(url_for("admin.lista", tabla=tabla))


@admin_bp.route("/<tabla>/<int:id>/restaurar", methods=["POST"])
@login_required
def restaurar(tabla, id):
    escribible(tabla)
    obtener(tabla, id)
    ejecutar(f"UPDATE `{tabla}` SET borrado = 0 WHERE id = %s AND borrado = 1", (id,))
    registrar("restaurar", tabla, id, "borrado = 0")
    invalidar()
    flash("Registro restaurado.", "ok")
    return redirect(url_for("admin.ver", tabla=tabla, id=id))