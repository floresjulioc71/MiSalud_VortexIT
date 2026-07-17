#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(pwd)"
PAYLOAD="$PROJECT_ROOT/build_023_payload"
BACKUP_DIR="$PROJECT_ROOT/.build_backups/build_023_$(date +%Y%m%d_%H%M%S)"

if [[ ! -f "$PROJECT_ROOT/pubspec.yaml" || ! -d "$PROJECT_ROOT/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

if [[ ! -d "$PAYLOAD" ]]; then
  echo "ERROR: no se encontró build_023_payload. Volvé a descomprimir el ZIP."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

backup_file() {
  local relative="$1"
  if [[ -f "$PROJECT_ROOT/$relative" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
    cp "$PROJECT_ROOT/$relative" "$BACKUP_DIR/$relative"
  fi
}

install_source() {
  local source_relative="$1"
  local target_relative="${source_relative%.src}"
  backup_file "$target_relative"
  mkdir -p "$PROJECT_ROOT/$(dirname "$target_relative")"
  cp "$PAYLOAD/$source_relative" "$PROJECT_ROOT/$target_relative"
}

backup_file "pubspec.yaml"
install_source "lib/features/health_controls/widgets/health_metric.dart.src"
install_source "lib/features/health_controls/screens/health_controls_evolution_screen.dart.src"
install_source "lib/features/health_controls/screens/health_controls_screen.dart.src"
install_source "test/features/health_controls/health_metric_test.dart.src"

python3 - <<'PY'
from pathlib import Path

path = Path('pubspec.yaml')
text = path.read_text()
if '  fl_chart:' not in text:
    marker = '  cupertino_icons: ^1.0.8\n'
    if marker not in text:
        raise SystemExit('ERROR: no se encontró el punto de inserción en pubspec.yaml')
    text = text.replace(marker, marker + '  fl_chart: ^1.2.0\n', 1)
    path.write_text(text)
PY

rm -rf "$PAYLOAD"

flutter pub get
dart fix --apply lib/features/health_controls || true
dart format lib/features/health_controls test/features/health_controls

echo
echo "Build 023 instalado correctamente."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validación sugerida:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
