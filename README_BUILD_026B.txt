MiSalud_VortexIT - Build 026B

Incluye pantalla principal, formulario, CRUD, búsqueda, filtros, adjuntos y prueba de interfaz.
No integra todavía el Dashboard ni la apertura externa del archivo.

Instalación:
cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026B.zip
chmod +x apply_build_026b.sh
./apply_build_026b.sh

Validación:
flutter analyze
flutter test test/features/clinical_documents
flutter test
