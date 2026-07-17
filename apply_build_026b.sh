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
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026b_$STAMP"
mkdir -p "$BACKUP_DIR"
[[ -d "$PROJECT_DIR/lib/features/clinical_documents" ]] && cp -a "$PROJECT_DIR/lib/features/clinical_documents" "$BACKUP_DIR/"
if [[ -d "$PROJECT_DIR/test/features/clinical_documents" ]]; then mkdir -p "$BACKUP_DIR/test"; cp -a "$PROJECT_DIR/test/features/clinical_documents" "$BACKUP_DIR/test/"; fi
mkdir -p "$PROJECT_DIR/lib/features/clinical_documents/screens" "$PROJECT_DIR/lib/features/clinical_documents/widgets" "$PROJECT_DIR/test/features/clinical_documents"
cp -a "$PAYLOAD_DIR/lib/features/clinical_documents/screens/." "$PROJECT_DIR/lib/features/clinical_documents/screens/"
cp -a "$PAYLOAD_DIR/lib/features/clinical_documents/widgets/." "$PROJECT_DIR/lib/features/clinical_documents/widgets/"
cp -a "$PAYLOAD_DIR/test/features/clinical_documents/." "$PROJECT_DIR/test/features/clinical_documents/"
dart format "$PROJECT_DIR/lib/features/clinical_documents" "$PROJECT_DIR/test/features/clinical_documents"
rm -rf "$PAYLOAD_DIR"
echo "Build 026B instalado. Respaldo: $BACKUP_DIR"
echo "Validar: flutter analyze && flutter test test/features/clinical_documents && flutter test"
