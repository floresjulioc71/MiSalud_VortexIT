#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

FORM_FILE="$PROJECT_DIR/lib/features/clinical_documents/screens/clinical_document_form_screen.dart"
LIST_FILE="$PROJECT_DIR/lib/features/clinical_documents/screens/clinical_documents_screen.dart"

for file in "$FORM_FILE" "$LIST_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: no se encontró $file"
    exit 1
  fi
done

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026b_r1_$STAMP"
mkdir -p "$BACKUP_DIR"

cp "$FORM_FILE" "$BACKUP_DIR/"
cp "$LIST_FILE" "$BACKUP_DIR/"

python3 - "$FORM_FILE" "$LIST_FILE" <<'PY'
from pathlib import Path
import sys

for raw_path in sys.argv[1:]:
    path = Path(raw_path)
    text = path.read_text(encoding="utf-8")

    old = text

    text = text.replace(
        "DropdownButtonFormField<ClinicalDocumentType>(\n"
        "                value: _type,",
        "DropdownButtonFormField<ClinicalDocumentType>(\n"
        "                initialValue: _type,"
    )

    text = text.replace(
        "DropdownButtonFormField<ClinicalDocumentType?>(\n"
        "                    value: _selectedType,",
        "DropdownButtonFormField<ClinicalDocumentType?>(\n"
        "                    initialValue: _selectedType,"
    )

    if text == old:
        print(f"AVISO: no se encontraron reemplazos pendientes en {path.name}")

    path.write_text(text, encoding="utf-8")
PY

dart format "$FORM_FILE" "$LIST_FILE"

echo
echo "Build 026B-R1 instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validar con:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
