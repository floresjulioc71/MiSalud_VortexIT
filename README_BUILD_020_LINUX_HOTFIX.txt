MiSalud_VortexIT - Build 020 Linux Hotfix

Problema corregido:
CMake no encontraba:
build/linux/x64/debug/bundle/lib/libpdfium.so

Causa:
La integración Linux del paquete printing necesita una versión y arquitectura
de PDFium fijadas explícitamente en linux/CMakeLists.txt. Además, el árbol de
compilación anterior podía conservar una descarga o configuración incompleta.

Aplicación:

cd /home/jflores/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_020_Linux_Hotfix.zip
chmod +x apply_build_020_linux_hotfix.sh
./apply_build_020_linux_hotfix.sh

Validación:

flutter analyze
flutter test
flutter run -d linux
