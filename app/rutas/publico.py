
from flask import Blueprint, render_template

from config import Config
from db import consultar_uno

publico_bp = Blueprint("publico", __name__)


@publico_bp.route("/")
def inicio():
    fila = consultar_uno(
        "SELECT COUNT(*) AS n FROM information_schema.tables "
        "WHERE table_schema = %s AND table_type = 'BASE TABLE' "
        "AND RIGHT(table_name, 4) <> '_bak'",
        (Config.DB_NAME,),
    )
    return render_template("inicio.html", n_tablas=fila["n"])