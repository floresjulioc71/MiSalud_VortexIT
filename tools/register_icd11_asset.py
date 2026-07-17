#!/usr/bin/env python3
from pathlib import Path

pubspec = Path("pubspec.yaml")
text = pubspec.read_text(encoding="utf-8")

asset_line = "    - assets/data/icd11_es_2026_01.json"

if asset_line in text:
    print("El asset CIE-11 ya está registrado.")
    raise SystemExit(0)

flutter_marker = "flutter:\n"

if flutter_marker not in text:
    raise SystemExit("No se encontró la sección flutter: en pubspec.yaml")

uses_material = "  uses-material-design: true"

if uses_material in text:
    text = text.replace(
        uses_material,
        uses_material
        + "\n  assets:\n"
        + asset_line,
        1,
    )
else:
    text = text.replace(
        flutter_marker,
        flutter_marker
        + "  assets:\n"
        + asset_line
        + "\n",
        1,
    )

pubspec.write_text(text, encoding="utf-8")
print("Asset CIE-11 agregado a pubspec.yaml.")
