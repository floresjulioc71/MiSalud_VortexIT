#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

if [[ ! -d "$PAYLOAD_DIR" ]]; then
  echo "ERROR: no se encontró la carpeta payload."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_025_$STAMP"
mkdir -p "$BACKUP_DIR"

echo "==> Creando respaldo en $BACKUP_DIR"
cp "$PROJECT_DIR/pubspec.yaml" "$BACKUP_DIR/pubspec.yaml"
if [[ -d "$PROJECT_DIR/lib/features/vaccines" ]]; then
  cp -a "$PROJECT_DIR/lib/features/vaccines" "$BACKUP_DIR/"
fi

echo "==> Instalando módulo Vacunas"
mkdir -p "$PROJECT_DIR/lib/features/vaccines"
cp -a "$PAYLOAD_DIR/lib/features/vaccines/." \
      "$PROJECT_DIR/lib/features/vaccines/"

mkdir -p "$PROJECT_DIR/test/features/vaccines"
cp -a "$PAYLOAD_DIR/test/features/vaccines/." \
      "$PROJECT_DIR/test/features/vaccines/"

echo "==> Verificando dependencias"
python3 - "$PROJECT_DIR/pubspec.yaml" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

def add_dependency(name: str, version: str) -> None:
    if any(line.strip().startswith(f"{name}:") for line in lines):
        return
    index = next(
        (i for i, line in enumerate(lines) if line.startswith("dev_dependencies:")),
        None,
    )
    if index is None:
        raise SystemExit("No se encontró dev_dependencies en pubspec.yaml")
    lines.insert(index, f"  {name}: {version}")

add_dependency("uuid", "^4.5.1")
add_dependency("open_filex", "^4.7.0")

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

echo "==> Integrando acceso desde Estudios Médicos"
STUDIES_SCREEN="$PROJECT_DIR/lib/features/medical_studies/screens/medical_studies_screen.dart"
if [[ -f "$STUDIES_SCREEN" ]]; then
  python3 - "$STUDIES_SCREEN" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

import_line = "import '../../vaccines/screens/vaccines_screen.dart';\n"
if "vaccines_screen.dart" not in text:
    marker = "import 'package:flutter/material.dart';\n"
    text = text.replace(marker, marker + "\n" + import_line, 1)

button = """          IconButton(
            tooltip: 'Vacunas',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const VaccinesScreen(),
              ),
            ),
            icon: const Icon(Icons.vaccines_outlined),
          ),
"""

if "tooltip: 'Vacunas'" not in text:
    marker = "        actions: <Widget>[\n"
    if marker in text:
        text = text.replace(marker, marker + button, 1)
    else:
        appbar = "      appBar: AppBar(title: const Text('Estudios Médicos')),\n"
        replacement = """      appBar: AppBar(
        title: const Text('Estudios Médicos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Vacunas',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const VaccinesScreen(),
              ),
            ),
            icon: const Icon(Icons.vaccines_outlined),
          ),
        ],
      ),
"""
        if appbar in text:
            text = text.replace(appbar, replacement, 1)
        else:
            print("AVISO: acceso automático no insertado. El módulo quedó instalado.")

path.write_text(text, encoding="utf-8")
PY
else
  echo "AVISO: Estudios Médicos no encontrado. Vacunas quedó instalado sin acceso automático."
fi

flutter pub get

dart format \
  "$PROJECT_DIR/lib/features/vaccines" \
  "$PROJECT_DIR/test/features/vaccines"

if [[ -f "$STUDIES_SCREEN" ]]; then
  dart format "$STUDIES_SCREEN"
fi

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 025 instalado."
echo "Validá con:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
