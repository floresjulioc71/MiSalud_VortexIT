MiSalud_VortexIT - Build 026A

Incluye modelo, almacenamiento por integrante, archivos locales y pruebas.
No modifica Dashboard ni navegación.

INSTALACIÓN
cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026A.zip
chmod +x apply_build_026a.sh
./apply_build_026a.sh

VALIDACIÓN
flutter analyze
flutter test test/features/clinical_documents
flutter test
