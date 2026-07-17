#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

python3 <<'PYPATCH'
from pathlib import Path
path = Path('lib/features/dashboard/screens/dashboard_screen.dart')
if not path.exists():
    raise SystemExit('ERROR: no se encontró dashboard_screen.dart')
text = path.read_text(encoding='utf-8')
import_line = "import '../../health_controls/screens/health_controls_screen.dart';\n"
if import_line not in text:
    first_class = text.find('class DashboardScreen')
    if first_class < 0:
        raise SystemExit('ERROR: no se encontró DashboardScreen.')
    text = text[:first_class] + import_line + '\n' + text[first_class:]
old = """            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppConstants.pendingModule),
                ),
              );
            },"""
new = """            onTap: () {
              if (item.$1 == 'Controles' ||
                  item.$1 == 'Controles de Salud') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HealthControlsScreen(),
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppConstants.pendingModule),
                ),
              );
            },"""
if old in text:
    text = text.replace(old, new, 1)
elif 'HealthControlsScreen()' not in text:
    raise SystemExit('ERROR: el Dashboard actual usa una estructura distinta. No se modificó el archivo.')
path.write_text(text, encoding='utf-8')
PYPATCH

flutter pub get

dart format \
  lib/features/health_controls \
  lib/features/dashboard/screens/dashboard_screen.dart \
  test/features/health_controls/health_control_test.dart

echo
echo "Build 022 aplicado."
echo "Ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
