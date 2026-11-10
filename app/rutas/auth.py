
from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required
from werkzeug.security import check_password_hash

from config import Config

auth_bp = Blueprint("auth", __name__)

login_manager = LoginManager()
login_manager.login_view = "auth.login"
login_manager.login_message = "Inicia sesión para entrar al panel."


class Admin(UserMixin):
    """Único usuario administrador (sus datos vienen del .env)."""
    def __init__(self, usuario):
        self.id = usuario


@login_manager.user_loader
def cargar_usuario(user_id):
    if user_id == Config.ADMIN_USER:
        return Admin(user_id)
    return None


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        usuario = request.form.get("usuario", "").strip()
        clave = request.form.get("clave", "")

        if (usuario == Config.ADMIN_USER
                and Config.ADMIN_PASSWORD_HASH
                and check_password_hash(Config.ADMIN_PASSWORD_HASH, clave)):
            login_user(Admin(usuario))
            return redirect(url_for("dashboard.dashboard"))

        flash("Usuario o clave incorrectos.")

    return render_template("login.html")


@auth_bp.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("publico.inicio"))