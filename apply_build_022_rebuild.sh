#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

if [[ ! -d "payload/lib/features/health_controls" ]]; then
  echo "ERROR: el paquete está incompleto. Falta payload/lib/features/health_controls."
  exit 1
fi

TARGET_DASHBOARD="lib/features/dashboard/screens/dashboard_screen.dart"
BACKUP_DASHBOARD="${TARGET_DASHBOARD}.backup_before_build_022_rebuild"

if [[ ! -f "$TARGET_DASHBOARD" ]]; then
  echo "ERROR: no se encontró $TARGET_DASHBOARD"
  exit 1
fi

PACKAGE_NAME="$(awk '/^name:[[:space:]]*/ {print $2; exit}' pubspec.yaml)"
if [[ -z "$PACKAGE_NAME" ]]; then
  echo "ERROR: no se pudo determinar el nombre del paquete desde pubspec.yaml."
  exit 1
fi

echo "Aplicando Build 022 reconstruido..."

cp -f "$TARGET_DASHBOARD" "$BACKUP_DASHBOARD"

# Elimina residuos creados por los Hotfix anteriores.
rm -rf files

mkdir -p lib/features/health_controls/models
mkdir -p lib/features/health_controls/services
mkdir -p lib/features/health_controls/screens
mkdir -p lib/features/dashboard/screens
mkdir -p test/features/health_controls

cp -f payload/lib/features/health_controls/models/health_control.dart \
  lib/features/health_controls/models/health_control.dart
cp -f payload/lib/features/health_controls/services/health_control_storage_service.dart \
  lib/features/health_controls/services/health_control_storage_service.dart
cp -f payload/lib/features/health_controls/services/health_control_pdf_service.dart \
  lib/features/health_controls/services/health_control_pdf_service.dart
cp -f payload/lib/features/health_controls/screens/health_control_form_screen.dart \
  lib/features/health_controls/screens/health_control_form_screen.dart
cp -f payload/lib/features/health_controls/screens/health_controls_screen.dart \
  lib/features/health_controls/screens/health_controls_screen.dart
cp -f payload/lib/features/dashboard/screens/dashboard_screen.dart \
  "$TARGET_DASHBOARD"
cp -f payload/test/features/health_controls/health_control_test.dart \
  test/features/health_controls/health_control_test.dart

python3 - "$PACKAGE_NAME" <<'PY'
from pathlib import Path
import sys
package_name = sys.argv[1]
path = Path('test/features/health_controls/health_control_test.dart')
text = path.read_text(encoding='utf-8')
text = text.replace('package:misalud_vortexit/', f'package:{package_name}/')
text = text.replace('package:mi_salud_vortex_it/', f'package:{package_name}/')
path.write_text(text, encoding='utf-8')
PY

flutter pub get

dart format \
  lib/features/health_controls \
  lib/features/dashboard/screens/dashboard_screen.dart \
  test/features/health_controls/health_control_test.dart

# Limpia artefactos del análisis anterior y fuerza una resolución fresca.
flutter clean
flutter pub get

echo
echo "Build 022 reconstruido y aplicado correctamente."
echo "Dashboard anterior respaldado en: $BACKUP_DASHBOARD"
echo "Nombre de paquete detectado: $PACKAGE_NAME"
echo
echo "Ejecutá ahora:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
