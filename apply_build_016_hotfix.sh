#!/usr/bin/env bash
set -euo pipefail

FILE="lib/features/consultations/screens/consultation_edit_screen.dart"

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: No se encontró $FILE"
  echo "Ejecutá este script desde la raíz de app_flutter."
  exit 1
fi

python3 - "$FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# Elimina el import circular que ya no se utiliza.
text = text.replace(
    "import 'consultation_screen.dart';\n",
    "",
)

helper = """String formatConsultationDateTime(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/${value.year} $hour:$minute';
}

"""

if "String formatConsultationDateTime(DateTime value)" not in text:
    marker = "class ConsultationEditScreen extends StatefulWidget"
    if marker not in text:
        raise SystemExit(
            "ERROR: No se encontró la clase ConsultationEditScreen."
        )
    text = text.replace(marker, helper + marker, 1)

path.write_text(text, encoding="utf-8")
print(f"Hotfix aplicado en {path}")
PY

dart format "$FILE"

echo
echo "Build 016 Hotfix aplicado correctamente."
echo "Ahora ejecutá:"
echo "  flutter analyze"
echo "  flutter test"
echo "  flutter run"
