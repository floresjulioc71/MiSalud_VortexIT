MiSalud_VortexIT - Build 026B-R2

Corrección puntual:
- Reemplaza el último uso deprecado de:
    value: _type
  por:
    initialValue: _type

Instalación:

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_026B_R2.zip
chmod +x apply_build_026b_r2.sh
./apply_build_026b_r2.sh

Validación:

flutter analyze
flutter test test/features/clinical_documents
flutter test
