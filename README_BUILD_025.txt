MiSalud_VortexIT - Build 025
Carnet digital de vacunación

INSTALACIÓN

cd ~/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_025.zip
chmod +x apply_build_025.sh
./apply_build_025.sh

VALIDACIÓN

flutter analyze
flutter test
flutter run -d linux

INCLUYE

- CRUD completo de vacunas.
- Dosis actual y total del esquema.
- Cálculo automático de estado.
- Esquema completo.
- Dosis pendiente.
- Refuerzo vencido.
- Próximo refuerzo dentro de 30 días.
- Laboratorio, lote, centro y profesional.
- Próxima dosis o refuerzo.
- Búsqueda y filtros por estado.
- Adjuntos PDF, JPG, JPEG y PNG.
- Vista previa de imágenes.
- Apertura de comprobantes.
- Almacenamiento separado por integrante familiar activo.
- Respaldo automático antes de instalar.
- Tres pruebas unitarias nuevas.
- Acceso automático desde Estudios Médicos.
