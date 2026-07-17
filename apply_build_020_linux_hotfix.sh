#!/usr/bin/env bash
set -euo pipefail

CMAKE_FILE="linux/CMakeLists.txt"

if [[ ! -f "pubspec.yaml" || ! -f "$CMAKE_FILE" ]]; then
  echo "ERROR: ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

python3 - "$CMAKE_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

settings = '''# Configuración fija de PDFium para printing en Linux.
set(PDFIUM_VERSION "4929" CACHE STRING "" FORCE)
set(PDFIUM_ARCH "x64" CACHE STRING "" FORCE)

'''

if 'set(PDFIUM_VERSION "4929"' not in text:
    marker = "project("
    pos = text.find(marker)

    if pos == -1:
        text = settings + text
    else:
        line_end = text.find("\n", pos)
        if line_end == -1:
            text += "\n\n" + settings
        else:
            text = text[:line_end + 1] + "\n" + settings + text[line_end + 1:]

    path.write_text(text, encoding="utf-8")
    print("Configuración PDFium agregada a linux/CMakeLists.txt.")
else:
    print("La configuración PDFium ya estaba presente.")
PY

echo "Limpiando compilación nativa anterior..."
flutter clean
rm -rf build/linux
rm -rf linux/flutter/ephemeral

echo "Recuperando dependencias..."
flutter pub get

echo
echo "Hotfix Linux aplicado."
echo "Ahora ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run -d linux"
