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
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026a_r1_$STAMP"

mkdir -p "$BACKUP_DIR"

if [[ -d "$PROJECT_DIR/lib/features/clinical_documents" ]]; then
  cp -a "$PROJECT_DIR/lib/features/clinical_documents" "$BACKUP_DIR/"
fi

mkdir -p "$PROJECT_DIR/lib/features/clinical_documents/models"
mkdir -p "$PROJECT_DIR/lib/features/clinical_documents/services"

cp "$PAYLOAD_DIR/lib/features/clinical_documents/models/clinical_document.dart" \
   "$PROJECT_DIR/lib/features/clinical_documents/models/clinical_document.dart"

cp "$PAYLOAD_DIR/lib/features/clinical_documents/services/clinical_document_file_service.dart" \
   "$PROJECT_DIR/lib/features/clinical_documents/services/clinical_document_file_service.dart"

cp "$PAYLOAD_DIR/lib/features/clinical_documents/services/clinical_document_storage_service.dart" \
   "$PROJECT_DIR/lib/features/clinical_documents/services/clinical_document_storage_service.dart"

dart format "$PROJECT_DIR/lib/features/clinical_documents"

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 026A-R1 instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validar con:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
