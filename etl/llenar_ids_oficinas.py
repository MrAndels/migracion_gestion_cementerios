# llenar_ids_oficinas.py
import os
import pymysql
from dotenv import load_dotenv

load_dotenv()
CONF = dict(host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "3306")),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME"),
            charset="utf8mb4")

con = pymysql.connect(**CONF)
cur = con.cursor()

# Solo códigos de oficina (ofi) que aparecen una sola vez entre las oficinas activas.
# Si el código solo existe borrado, se usa la de menor id.
cur.execute("""
    UPDATE consignaciones h
    JOIN (
      SELECT ofi,
             CAST(SUBSTRING_INDEX(GROUP_CONCAT(id ORDER BY borrado, id), ',', 1)
                  AS UNSIGNED) AS pid
      FROM oficinas
      WHERE ofi IS NOT NULL
      GROUP BY ofi
      HAVING SUM(borrado = 0) < 2
    ) p ON p.ofi = h.oficina
    SET h.oficina_id = p.pid
    WHERE h.id > 0
""")
con.commit()

cur.execute("SELECT COUNT(*), COALESCE(SUM(oficina_id IS NULL), 0) "
            "FROM consignaciones WHERE borrado = 0 AND oficina IS NOT NULL")
total, sin = cur.fetchone()
print(f"consignaciones.oficina_id: {total:,} activas con código, "
      f"{int(sin):,} sin enlace ({100 * int(sin) / total:.1f}%)")

cur.execute("SELECT oficina, COUNT(*) AS n FROM consignaciones "
            "WHERE borrado = 0 AND oficina IS NOT NULL AND oficina_id IS NULL "
            "GROUP BY oficina ORDER BY n DESC LIMIT 8")
for cod, n in cur.fetchall():
    print("    sin enlace:", repr(cod), "->", n, "filas")

con.close()
print("\nListo.")