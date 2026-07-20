MiSalud_VortexIT - Build 026C-R1

Corrección de compatibilidad para Linux.

Cambios:
- Detecta Linux antes de compartir archivos.
- Evita UnimplementedError de share_plus.
- Oculta Compartir en el menú contextual de Linux.
- Mantiene el botón en la vista de detalle con un mensaje informativo.
- Conserva el funcionamiento normal en Android y plataformas compatibles.
- Crea respaldo automático antes de modificar archivos.

Instalación:

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026C_R1.zip
chmod +x apply_build_026c_r1.sh
./apply_build_026c_r1.sh

Validación:

flutter analyze
flutter test test/features/clinical_documents
flutter test
flutter run -d linux
