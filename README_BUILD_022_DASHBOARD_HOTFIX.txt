MiSalud_VortexIT - Build 022 Dashboard Hotfix

Este Hotfix adapta la integración de Controles de Salud a la estructura real
del Dashboard del proyecto.

Cambios:
- conserva todas las rutas y tarjetas existentes;
- agrega la importación de HealthControlsScreen;
- conecta únicamente la tarjeta Controles;
- mantiene Informe PDF y Respaldo como módulos pendientes;
- crea una copia de seguridad del Dashboard anterior.

Aplicación desde la raíz de app_flutter:

unzip -o ~/Descargas/MiSalud_VortexIT_Build_022_Dashboard_Hotfix.zip
chmod +x apply_build_022_dashboard_hotfix.sh
./apply_build_022_dashboard_hotfix.sh

Validación:
flutter analyze
flutter test
flutter run -d linux
