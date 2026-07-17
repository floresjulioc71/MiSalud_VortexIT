MiSalud_VortexIT - Build 025 Final

Este paquete corrige los dos puntos pendientes del módulo Vacunas:

1. Reemplaza la referencia antigua VaccinesScreen por VaccineScreen
   dentro de Estudios Médicos.

2. Restablece el almacenamiento separado por integrante familiar,
   manteniendo la API existente:
   - initialize()
   - loadItems()
   - saveItem()
   - deleteItem()
   - clear()

INSTALACIÓN

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_025_Final.zip
chmod +x apply_build_025_final.sh
./apply_build_025_final.sh

VALIDACIÓN

flutter analyze
flutter test
flutter run -d linux
