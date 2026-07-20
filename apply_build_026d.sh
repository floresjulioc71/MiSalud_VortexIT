#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

MODULE_DIR="$PROJECT_DIR/lib/features/clinical_documents"
TEST_DIR="$PROJECT_DIR/test/features/clinical_documents"

if [[ ! -d "$MODULE_DIR" ]]; then
  echo "ERROR: no se encontró el módulo Documentos Clínicos."
  echo "Primero deben estar instalados los Builds 026A, 026B y 026C."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026d_$STAMP"

echo "==> Creando respaldo"
mkdir -p "$BACKUP_DIR"
cp -a "$MODULE_DIR" "$BACKUP_DIR/"

if [[ -d "$TEST_DIR" ]]; then
  mkdir -p "$BACKUP_DIR/test"
  cp -a "$TEST_DIR" "$BACKUP_DIR/test/"
fi

echo "==> Instalando pruebas de aceptación"
mkdir -p "$TEST_DIR"
cp -a "$PAYLOAD_DIR/test/features/clinical_documents/." "$TEST_DIR/"

echo "==> Limpiando archivos temporales del módulo"
find "$MODULE_DIR" -type f \
  \( -name '*.orig' -o -name '*.rej' -o -name '*~' \) \
  -delete

echo "==> Formateando"
dart format "$MODULE_DIR" "$TEST_DIR"

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 026D instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Ejecutá ahora:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
echo "  flutter run -d linux"
echo
echo "Prueba funcional:"
echo "  1. Abrir Documentos clínicos desde el Dashboard."
echo "  2. Crear un documento sin adjunto."
echo "  3. Crear otro con imagen o PDF."
echo "  4. Abrir, editar y eliminar registros."
echo "  5. Confirmar el mensaje de Linux al usar Compartir."
