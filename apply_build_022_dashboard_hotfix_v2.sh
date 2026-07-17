#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

TARGET="lib/features/dashboard/screens/dashboard_screen.dart"
SOURCE="files/lib/features/dashboard/screens/dashboard_screen.dart"
HEALTH_SCREEN="lib/features/health_controls/screens/health_controls_screen.dart"

if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: no se encontró $TARGET"
  exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "ERROR: el ZIP del Hotfix está incompleto: falta $SOURCE"
  exit 1
fi

if [[ ! -f "$HEALTH_SCREEN" ]]; then
  echo "ERROR: no se encontró $HEALTH_SCREEN"
  echo "Primero debe estar aplicado el módulo principal del Build 022."
  exit 1
fi

BACKUP="${TARGET}.backup_build_022_v2"
cp -f "$TARGET" "$BACKUP"
cp -f "$SOURCE" "$TARGET"

dart format "$TARGET"

echo
echo "Hotfix Dashboard Build 022 v2 aplicado correctamente."
echo "Respaldo creado en: $BACKUP"
echo
echo "Ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
