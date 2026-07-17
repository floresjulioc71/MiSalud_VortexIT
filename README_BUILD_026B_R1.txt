MiSalud_VortexIT - Build 026B-R1

Corrección:
- Sustituye el parámetro deprecado value por initialValue en los dos
  DropdownButtonFormField del módulo Documentos Clínicos.

Instalación:

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026B_R1.zip
chmod +x apply_build_026b_r1.sh
./apply_build_026b_r1.sh

Validación:

flutter analyze
flutter test test/features/clinical_documents
flutter test
