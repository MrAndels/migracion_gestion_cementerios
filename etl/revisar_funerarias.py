from collections import Counter
from pathlib import Path
from dbfread import DBF

f = next(p for p in Path("datos_originales/dbf").rglob("*")
         if p.suffix.lower() == ".dbf" and p.stem.lower() == "funerarias")

dbf0 = DBF(str(f), ignore_missing_memofile=True, char_decode_errors="replace")
print("Codificación que detecta dbfread:", dbf0.encoding)

regs = list(dbf0)
print("Registros:", len(regs))
print("NOMBR con datos:", sum(1 for r in regs if (r["NOMBR"] or "").strip()))
cont = Counter((r["COD_FUN"] or "").strip() for r in regs)
print("COD_FUN repetidos:", {k: v for k, v in cont.items() if v > 1})

for enc in ("cp850", "cp1252"):
    dbf = DBF(str(f), ignore_missing_memofile=True,
              char_decode_errors="replace", encoding=enc)
    raros = [(r["DIRECCION"] or "").strip() for r in dbf
             if any(ord(c) > 127 for c in (r["DIRECCION"] or ""))]
    print(f"\n--- Leído como {enc}: {len(raros)} direcciones con caracteres especiales ---")
    for d in raros[:6]:
        print("  ", d)