MiSalud_VortexIT - Build 026D
Cierre y aceptación final del módulo Documentos Clínicos.

Este build no modifica la lógica aprobada del módulo.
Agrega pruebas de aceptación y realiza limpieza técnica segura.

Incluye:
- Prueba de documento sin archivo adjunto.
- Prueba de datos principales en la vista de detalle.
- Prueba de la acción Editar.
- Limpieza de archivos temporales .orig, .rej y copias con ~.
- Formateo del módulo y sus pruebas.
- Respaldo automático antes de aplicar cambios.
- Checklist de validación funcional.

Instalación:

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026D.zip
chmod +x apply_build_026d.sh
./apply_build_026d.sh

Validación:

flutter analyze
flutter test test/features/clinical_documents
flutter test
flutter run -d linux

Criterio de aceptación:

- flutter analyze sin issues.
- Tests del módulo aprobados.
- Suite completa aprobada.
- Acceso desde Dashboard correcto.
- Alta, edición, búsqueda, filtros y eliminación correctos.
- Apertura de PDF e imágenes correcta.
- Linux controla Compartir sin lanzar excepciones.
