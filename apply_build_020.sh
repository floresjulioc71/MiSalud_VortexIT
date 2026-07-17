#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

python3 <<'PY'
from pathlib import Path

path = Path("pubspec.yaml")
text = path.read_text(encoding="utf-8")

dependencies = {
    "pdf": "^3.11.3",
    "printing": "^5.14.2",
}

lines = text.splitlines()
try:
    start = next(i for i, line in enumerate(lines) if line.strip() == "dependencies:")
except StopIteration:
    raise SystemExit("ERROR: pubspec.yaml no contiene dependencies:")

end = len(lines)
for i in range(start + 1, len(lines)):
    line = lines[i]
    if line and not line.startswith((" ", "\t")):
        end = i
        break

section = lines[start + 1:end]
existing = {
    line.split(":", 1)[0].strip()
    for line in section
    if ":" in line and not line.lstrip().startswith("#")
}

insert_at = end
new_lines = []
for name, version in dependencies.items():
    if name not in existing:
        new_lines.append(f"  {name}: {version}")

if new_lines:
    lines[insert_at:insert_at] = new_lines
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Dependencias PDF agregadas a pubspec.yaml.")
else:
    print("Las dependencias PDF ya estaban declaradas.")
PY

flutter pub get
dart format \
  lib/features/consultations/screens/consultation_timeline_screen.dart \
  lib/features/consultations/services/consultation_timeline_pdf_service.dart

echo
echo "Build 020 aplicado."
echo "Ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run"
