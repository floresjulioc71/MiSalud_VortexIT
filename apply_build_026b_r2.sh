#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
FORM_FILE="$PROJECT_DIR/lib/features/clinical_documents/screens/clinical_document_form_screen.dart"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -f "$FORM_FILE" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026b_r2_$STAMP"
mkdir -p "$BACKUP_DIR"
cp "$FORM_FILE" "$BACKUP_DIR/"

python3 - "$FORM_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

pattern = re.compile(
    r"(DropdownButtonFormField<ClinicalDocumentType>\(\s*)value:\s*_type,",
    re.MULTILINE,
)

updated, count = pattern.subn(
    r"\1initialValue: _type,",
    text,
)

if count == 0:
    # Fallback puntual por si el archivo fue reformateado de otra manera.
    updated = text.replace("value: _type,", "initialValue: _type,")
    count = 1 if updated != text else 0

if count == 0:
    raise SystemExit(
        "ERROR: no se encontró el parámetro value: _type en el formulario."
    )

path.write_text(updated, encoding="utf-8")
print(f"Correcciones aplicadas: {count}")
PY

dart format "$FORM_FILE"

echo
echo "Build 026B-R2 instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validar con:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
