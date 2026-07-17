#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

SOURCE="lib/features/health_controls/screens/health_controls_screen.dart"
TARGET="lib/features/dashboard/screens/dashboard_screen.dart"
HOTFIX_FILE="lib/features/dashboard/screens/dashboard_screen.dart"

if [[ ! -f "$SOURCE" ]]; then
  echo "ERROR: no se encontró $SOURCE"
  echo "El módulo del Build 022 no parece estar instalado."
  exit 1
fi

if [[ ! -f "$TARGET" ]]; then
  echo "ERROR: no se encontró $TARGET"
  exit 1
fi

cp "$TARGET" "${TARGET}.backup_build_022"
cp "$HOTFIX_FILE" "$TARGET"

dart format "$TARGET"

echo
echo "Hotfix del Dashboard para Build 022 aplicado correctamente."
echo "Copia de seguridad: ${TARGET}.backup_build_022"
echo
echo "Ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
