MiSalud_VortexIT - Build 026C
Integración final de Documentos Clínicos.

Incluye:
- Acceso desde la barra del Dashboard.
- Vista completa del documento.
- Vista previa de imágenes.
- Apertura externa de PDF e imágenes.
- Compartir archivos con share_plus.
- Acciones Ver, Compartir, Editar y Eliminar.
- Manejo de archivos faltantes.
- Prueba de la vista de detalle.
- Respaldo automático antes de instalar.

Instalación:

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026C.zip
chmod +x apply_build_026c.sh
./apply_build_026c.sh

Validación:

flutter analyze
flutter test test/features/clinical_documents
flutter test
flutter run -d linux
