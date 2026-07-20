#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"

if [[ ! -f "$PROJECT_DIR/pubspec.yaml" || ! -d "$PROJECT_DIR/lib" ]]; then
  echo "ERROR: ejecutá este instalador desde la raíz del proyecto Flutter."
  exit 1
fi

VIEW_FILE="$PROJECT_DIR/lib/features/clinical_documents/screens/clinical_document_view_screen.dart"
CARD_FILE="$PROJECT_DIR/lib/features/clinical_documents/widgets/clinical_document_card.dart"

for file in "$VIEW_FILE" "$CARD_FILE"; do
  if [[ ! -f "$file" ]]; then
    echo "ERROR: no se encontró $file"
    exit 1
  fi
done

STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_DIR/.build_backups/build_026c_r1_$STAMP"
mkdir -p "$BACKUP_DIR"

cp "$VIEW_FILE" "$BACKUP_DIR/"
cp "$CARD_FILE" "$BACKUP_DIR/"

python3 - "$VIEW_FILE" "$CARD_FILE" <<'PY'
from pathlib import Path
import sys

view_path = Path(sys.argv[1])
card_path = Path(sys.argv[2])

view_text = view_path.read_text(encoding="utf-8")
card_text = card_path.read_text(encoding="utf-8")

if "bool get _canShareFiles" not in view_text:
    marker = "class ClinicalDocumentViewScreen extends StatelessWidget {\n"
    replacement = (
        marker
        + "  bool get _canShareFiles => !Platform.isLinux;\n\n"
    )
    if marker not in view_text:
        raise SystemExit(
            "ERROR: no se encontró la clase ClinicalDocumentViewScreen."
        )
    view_text = view_text.replace(marker, replacement, 1)

old_button = """                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _runFileAction(
                              context,
                              () => ClinicalDocumentFileService.shareStoredFile(
                                filePath: document.filePath,
                                title: document.title,
                              ),
                            ),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartir'),
                          ),
                        ),
"""

new_button = """                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _canShareFiles
                                ? () => _runFileAction(
                                      context,
                                      () => ClinicalDocumentFileService
                                          .shareStoredFile(
                                        filePath: document.filePath,
                                        title: document.title,
                                      ),
                                    )
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Compartir archivos no está '
                                          'disponible en Linux. Esta función '
                                          'estará disponible en Android.',
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartir'),
                          ),
                        ),
"""

if old_button in view_text:
    view_text = view_text.replace(old_button, new_button, 1)
elif "Compartir archivos no está" not in view_text:
    raise SystemExit(
        "ERROR: no se encontró el botón Compartir esperado en la vista."
    )

if "import 'dart:io';" not in card_text:
    card_text = "import 'dart:io';\n\n" + card_text

old_menu = """                    if (document.hasFile)
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('Compartir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
"""

new_menu = """                    if (document.hasFile && !Platform.isLinux)
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('Compartir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
"""

if old_menu in card_text:
    card_text = card_text.replace(old_menu, new_menu, 1)
elif "!Platform.isLinux" not in card_text:
    raise SystemExit(
        "ERROR: no se encontró la opción Compartir esperada en la tarjeta."
    )

view_path.write_text(view_text, encoding="utf-8")
card_path.write_text(card_text, encoding="utf-8")
PY

dart format "$VIEW_FILE" "$CARD_FILE"

echo
echo "Build 026C-R1 instalado."
echo "Respaldo: $BACKUP_DIR"
echo
echo "Validación:"
echo "  flutter analyze"
echo "  flutter test test/features/clinical_documents"
echo "  flutter test"
echo "  flutter run -d linux"
