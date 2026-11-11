# app/app.py
from flask import Flask, render_template
from flask_wtf.csrf import CSRFProtect

from config import Config
from extensiones import limiter
from rutas.publico import publico_bp
from rutas.auth import auth_bp, login_manager
from rutas.dashboard import dashboard_bp
from rutas.admin import admin_bp
from rutas.consulta import consulta_bp

csrf = CSRFProtect()


def crear_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    csrf.init_app(app)
    login_manager.init_app(app)
    limiter.init_app(app)

    app.register_blueprint(publico_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(consulta_bp)

    @app.errorhandler(429)
    def demasiados_intentos(e):
        return render_template("limite.html"), 429

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(debug=True)