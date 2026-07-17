MiSalud_VortexIT - Build 025R
Reconstrucción compatible del módulo Vacunas

INSTALACIÓN

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_025R.zip
chmod +x apply_build_025R.sh
./apply_build_025R.sh

VALIDACIÓN

flutter analyze
flutter test
flutter run -d linux

CORRECCIONES

- Conserva VaccineItem.
- Conserva saveItem(), deleteItem() y loadItems().
- Elimina la implementación duplicada VaccineRecord.
- Elimina las pantallas duplicadas del Build 025 anterior.
- Mantiene compatibilidad con vaccine_screen.dart y vaccine_test.dart.
- Añade inicialización asíncrona sin romper loadItems() síncrono.

FUNCIONES

- CRUD de vacunas.
- Enfermedad que previene.
- Número de dosis y total del esquema.
- Laboratorio y lote.
- Lugar y profesional.
- Próxima dosis.
- Estados automáticos.
- Búsqueda y filtros.
- Comprobantes PDF, JPG, JPEG y PNG.
- Vista de detalles y apertura de adjuntos.
- Respaldo automático.
