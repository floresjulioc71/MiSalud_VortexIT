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
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_025_final_$STAMP"

mkdir -p "$BACKUP_DIR"

echo "==> Creando respaldo"
if [[ -d "$PROJECT_DIR/lib/features/vaccines" ]]; then
  cp -a "$PROJECT_DIR/lib/features/vaccines" "$BACKUP_DIR/"
fi

STUDIES_SCREEN="$PROJECT_DIR/lib/features/medical_studies/screens/medical_studies_screen.dart"
if [[ -f "$STUDIES_SCREEN" ]]; then
  mkdir -p "$BACKUP_DIR/medical_studies"
  cp "$STUDIES_SCREEN" "$BACKUP_DIR/medical_studies/"
fi

echo "==> Instalando servicio definitivo de Vacunas"
cp "$PAYLOAD_DIR/lib/features/vaccines/services/vaccine_storage_service.dart" \
   "$PROJECT_DIR/lib/features/vaccines/services/vaccine_storage_service.dart"

echo "==> Corrigiendo integración con Estudios Médicos"
if [[ -f "$STUDIES_SCREEN" ]]; then
  python3 - "$STUDIES_SCREEN" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

text = text.replace(
    "import '../../vaccines/screens/vaccines_screen.dart';",
    "import '../../vaccines/screens/vaccine_screen.dart';",
)
text = text.replace("const VaccinesScreen()", "const VaccineScreen()")
text = text.replace("VaccinesScreen()", "VaccineScreen()")

path.write_text(text, encoding="utf-8")
PY
fi

echo "==> Eliminando restos duplicados"
rm -f "$PROJECT_DIR/lib/features/vaccines/models/vaccine_record.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccine_form_screen.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccines_screen.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccine_view_screen.dart"
rm -f "$PROJECT_DIR/test/features/vaccines/vaccine_record_test.dart"

dart format \
  "$PROJECT_DIR/lib/features/vaccines/services/vaccine_storage_service.dart"

if [[ -f "$STUDIES_SCREEN" ]]; then
  dart format "$STUDIES_SCREEN"
fi

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 025 Final instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validar con:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
