MiSalud_VortexIT - Build 016 Hotfix

Corrige:
- import no utilizado de consultation_screen.dart
- método formatConsultationDateTime faltante
- dependencia entre ConsultationEditScreen y ConsultationScreen

Aplicación:

cd /home/jflores/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_016_Hotfix.zip
chmod +x apply_build_016_hotfix.sh
./apply_build_016_hotfix.sh

Después:

flutter analyze
flutter test
flutter run
