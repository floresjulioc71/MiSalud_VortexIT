MiSalud_VortexIT - Build 022

Controles de Salud completo:
- CRUD y persistencia local
- presión, frecuencia cardíaca, SpO2, temperatura, peso y glucemia
- observaciones y fecha/hora
- filtros de 30/90 días, 1 año y rango personalizado
- PDF de controles visibles
- imprimir, guardar y compartir
- integración con Dashboard
- 2 pruebas unitarias nuevas

Aplicación:
cd /home/jflores/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_022.zip
chmod +x apply_build_022.sh
./apply_build_022.sh

Validación:
flutter analyze
flutter test
flutter run -d linux
