
import os
from pathlib import Path
from dotenv import load_dotenv

# El .env está en la carpeta de arriba (raíz del proyecto)
RAIZ = Path(__file__).resolve().parent.parent
load_dotenv(RAIZ / ".env")


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "cambiar-esto-en-produccion")

    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD")
    DB_NAME = os.getenv("DB_NAME", "gestion_cementerios")
    ADMIN_USER = os.getenv("ADMIN_USER", "admin")
    ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH")