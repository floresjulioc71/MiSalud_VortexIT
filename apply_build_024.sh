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
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_024_$STAMP"
mkdir -p "$BACKUP_DIR"

echo "==> Creando respaldo en $BACKUP_DIR"
cp "$PROJECT_DIR/pubspec.yaml" "$BACKUP_DIR/pubspec.yaml"
if [[ -d "$PROJECT_DIR/lib/features/medical_studies" ]]; then
  cp -a "$PROJECT_DIR/lib/features/medical_studies" "$BACKUP_DIR/"
fi
if [[ -f "$PROJECT_DIR/lib/features/health_controls/screens/health_controls_screen.dart" ]]; then
  mkdir -p "$BACKUP_DIR/health_controls"
  cp "$PROJECT_DIR/lib/features/health_controls/screens/health_controls_screen.dart" \
     "$BACKUP_DIR/health_controls/"
fi

echo "==> Instalando módulo Estudios Médicos"
mkdir -p "$PROJECT_DIR/lib/features/medical_studies"
cp -a "$PAYLOAD_DIR/lib/features/medical_studies/." \
      "$PROJECT_DIR/lib/features/medical_studies/"

mkdir -p "$PROJECT_DIR/test/features/medical_studies"
cp -a "$PAYLOAD_DIR/test/features/medical_studies/." \
      "$PROJECT_DIR/test/features/medical_studies/"

echo "==> Actualizando dependencias"
python3 - "$PROJECT_DIR/pubspec.yaml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()
lines = text.splitlines()
def add_dependency(name, version):
    global lines
    if any(line.strip().startswith(f"{name}:") for line in lines):
        return
    try:
        idx = next(i for i,l in enumerate(lines) if l.startswith("dev_dependencies:"))
    except StopIteration:
        raise SystemExit("No se encontró dev_dependencies en pubspec.yaml")
    lines.insert(idx, f"  {name}: {version}")
add_dependency("uuid", "^4.6.0")
add_dependency("open_filex", "^4.7.0")
p.write_text("\n".join(lines) + "\n")
PY

HEALTH_SCREEN="$PROJECT_DIR/lib/features/health_controls/screens/health_controls_screen.dart"
if [[ -f "$HEALTH_SCREEN" ]]; then
  echo "==> Agregando acceso a Estudios Médicos desde Controles"
  python3 - "$HEALTH_SCREEN" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
text = p.read_text()

import_line = "import '../../medical_studies/screens/medical_studies_screen.dart';\n"
if "medical_studies_screen.dart" not in text:
    marker = "import 'package:flutter/material.dart';\n"
    text = text.replace(marker, marker + "\n" + import_line, 1)

button = '''          IconButton(
            tooltip: 'Estudios médicos',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const MedicalStudiesScreen(),
              ),
            ),
            icon: const Icon(Icons.biotech_outlined),
          ),
'''
if "tooltip: 'Estudios médicos'" not in text:
    marker = "        actions: <Widget>[\n"
    if marker in text:
        text = text.replace(marker, marker + button, 1)
    else:
        print("AVISO: no se encontró AppBar.actions; el módulo quedó instalado sin acceso automático.")

p.write_text(text)
PY
else
  echo "AVISO: no se encontró HealthControlsScreen. El módulo quedó instalado, pero requiere acceso manual."
fi

echo "==> Instalando dependencias"
flutter pub get

echo "==> Formateando"
dart format \
  "$PROJECT_DIR/lib/features/medical_studies" \
  "$PROJECT_DIR/test/features/medical_studies"

if [[ -f "$HEALTH_SCREEN" ]]; then
  dart format "$HEALTH_SCREEN"
fi

echo "==> Eliminando archivos temporales del paquete"
rm -rf "$PAYLOAD_DIR"

echo
echo "Build 024 instalado."
echo "Validá con:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
