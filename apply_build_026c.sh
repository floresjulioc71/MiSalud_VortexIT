#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026c_$STAMP"
mkdir -p "$BACKUP_DIR"

echo "==> Creando respaldo"
cp "$PROJECT_DIR/pubspec.yaml" "$BACKUP_DIR/pubspec.yaml"

if [[ -d "$PROJECT_DIR/lib/features/clinical_documents" ]]; then
  cp -a "$PROJECT_DIR/lib/features/clinical_documents" "$BACKUP_DIR/"
fi

DASHBOARD_FILE="$(find "$PROJECT_DIR/lib" -type f -name 'dashboard_screen.dart' | head -n 1 || true)"
if [[ -n "$DASHBOARD_FILE" ]]; then
  mkdir -p "$BACKUP_DIR/dashboard"
  cp "$DASHBOARD_FILE" "$BACKUP_DIR/dashboard/"
fi

echo "==> Instalando Build 026C"
mkdir -p "$PROJECT_DIR/lib/features/clinical_documents"
cp -a "$PAYLOAD_DIR/lib/features/clinical_documents/." \
  "$PROJECT_DIR/lib/features/clinical_documents/"

mkdir -p "$PROJECT_DIR/test/features/clinical_documents"
cp -a "$PAYLOAD_DIR/test/features/clinical_documents/." \
  "$PROJECT_DIR/test/features/clinical_documents/"

echo "==> Verificando dependencias"
python3 - "$PROJECT_DIR/pubspec.yaml" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

def add_dependency(name: str, version: str) -> None:
    if any(line.strip().startswith(f"{name}:") for line in lines):
        return

    try:
        index = next(
            i for i, line in enumerate(lines)
            if line.startswith("dev_dependencies:")
        )
    except StopIteration:
        raise SystemExit("ERROR: no se encontró dev_dependencies en pubspec.yaml")

    lines.insert(index, f"  {name}: {version}")

add_dependency("open_filex", "^4.7.0")
add_dependency("share_plus", "^12.0.0")

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

if [[ -n "$DASHBOARD_FILE" ]]; then
  echo "==> Integrando acceso en el Dashboard"
  python3 - "$DASHBOARD_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

import_line = (
    "import '../../clinical_documents/screens/"
    "clinical_documents_screen.dart';\n"
)

if "clinical_documents_screen.dart" not in text:
    flutter_import = "import 'package:flutter/material.dart';\n"
    if flutter_import not in text:
        raise SystemExit(
            "ERROR: no se encontró el import principal de Flutter en Dashboard."
        )
    text = text.replace(
        flutter_import,
        flutter_import + "\n" + import_line,
        1,
    )

button = """          IconButton(
            tooltip: 'Documentos clínicos',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const ClinicalDocumentsScreen(),
              ),
            ),
            icon: const Icon(Icons.folder_shared_outlined),
          ),
"""

if "tooltip: 'Documentos clínicos'" not in text:
    patterns = [
        r"(?P<indent>\s*)actions:\s*<Widget>\[\s*\n",
        r"(?P<indent>\s*)actions:\s*\[\s*\n",
    ]

    inserted = False
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            text = text[:match.end()] + button + text[match.end():]
            inserted = True
            break

    if not inserted:
        app_bar_pattern = re.compile(r"appBar:\s*AppBar\(\s*\n")
        match = app_bar_pattern.search(text)
        if match:
            actions_block = (
                "        actions: <Widget>[\n"
                + button
                + "        ],\n"
            )
            text = text[:match.end()] + actions_block + text[match.end():]
            inserted = True

    if not inserted:
        print(
            "AVISO: no se pudo insertar el botón automáticamente. "
            "El módulo quedó instalado y puede abrirse desde "
            "ClinicalDocumentsScreen."
        )

path.write_text(text, encoding="utf-8")
PY
else
  echo "AVISO: no se encontró dashboard_screen.dart."
  echo "El módulo quedó instalado sin acceso automático en el Dashboard."
fi

echo "==> Instalando dependencias"
flutter pub get

echo "==> Formateando"
dart format \
  "$PROJECT_DIR/lib/features/clinical_documents" \
  "$PROJECT_DIR/test/features/clinical_documents"

if [[ -n "$DASHBOARD_FILE" ]]; then
  dart format "$DASHBOARD_FILE"
fi

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 026C instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validación:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
echo "  flutter run -d linux"
