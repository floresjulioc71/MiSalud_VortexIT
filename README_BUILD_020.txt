MiSalud_VortexIT - Build 020
Exportación de Evolución Clínica a PDF

Incluye:
- botón PDF en Evolución clínica
- exportación de las consultas visibles
- respeta búsqueda y filtros activos
- resumen de consultas, médicos y diagnósticos
- detalle de profesional, motivo, diagnósticos, tratamiento,
  medicación, estudios, próximo control y observaciones
- paginado, fecha de generación y nombre automático
- usa el diálogo nativo de impresión/guardado PDF
- no modifica modelos ni almacenamiento

Aplicación:

cd /home/jflores/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_020.zip
chmod +x apply_build_020.sh
./apply_build_020.sh

Validación:

flutter analyze
flutter test
flutter run
