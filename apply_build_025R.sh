#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="$SCRIPT_DIR/payload"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá el instalador desde la raíz del proyecto Flutter."
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_025R_$STAMP"

mkdir -p "$BACKUP_DIR"
cp "$PROJECT_DIR/pubspec.yaml" "$BACKUP_DIR/pubspec.yaml"

if [[ -d "$PROJECT_DIR/lib/features/vaccines" ]]; then
  cp -a "$PROJECT_DIR/lib/features/vaccines" "$BACKUP_DIR/"
fi

if [[ -d "$PROJECT_DIR/test/features/vaccines" ]]; then
  cp -a "$PROJECT_DIR/test/features/vaccines" "$BACKUP_DIR/test_vaccines"
fi

echo "==> Eliminando implementación duplicada"
rm -f "$PROJECT_DIR/lib/features/vaccines/models/vaccine_record.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccine_form_screen.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccines_screen.dart"
rm -f "$PROJECT_DIR/lib/features/vaccines/screens/vaccine_view_screen.dart"
rm -f "$PROJECT_DIR/test/features/vaccines/vaccine_record_test.dart"

echo "==> Instalando Build 025R"
mkdir -p "$PROJECT_DIR/lib/features/vaccines/models"
mkdir -p "$PROJECT_DIR/lib/features/vaccines/services"
mkdir -p "$PROJECT_DIR/lib/features/vaccines/screens"

cp -a "$PAYLOAD_DIR/lib/features/vaccines/." \
      "$PROJECT_DIR/lib/features/vaccines/"

python3 - "$PROJECT_DIR/pubspec.yaml" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
lines = path.read_text(encoding="utf-8").splitlines()

def add_dependency(name: str, version: str) -> None:
    if any(line.strip().startswith(f"{name}:") for line in lines):
        return
    index = next(
        (i for i, line in enumerate(lines) if line.startswith("dev_dependencies:")),
        None,
    )
    if index is None:
        raise SystemExit("No se encontró dev_dependencies en pubspec.yaml")
    lines.insert(index, f"  {name}: {version}")

add_dependency("uuid", "^4.5.1")
add_dependency("open_filex", "^4.7.0")

path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

flutter pub get

dart format \
  "$PROJECT_DIR/lib/features/vaccines"

rm -rf "$PAYLOAD_DIR"

echo
echo "Build 025R instalado correctamente."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validar con:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
