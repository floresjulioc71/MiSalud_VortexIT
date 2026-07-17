MiSalud_VortexIT - Build 021
Guardar y compartir Evolución Clínica en PDF

Incluye:
- menú PDF unificado en Evolución clínica
- imprimir o guardar mediante el diálogo nativo existente
- guardar el PDF como archivo con selector de ubicación en Linux/Windows/macOS
- compartir el PDF mediante las aplicaciones disponibles en el sistema
- conserva búsqueda, filtros y período activos
- reutiliza exactamente el generador PDF del Build 020
- nombre automático: Evolucion_Clinica_AAAA-MM-DD.pdf
- mensaje de confirmación con la ruta cuando se guarda el archivo
- no modifica modelos ni almacenamiento clínico

Aplicación:

cd /home/jflores/apps/MiSalud_VortexIT/app_flutter
unzip -o ~/Descargas/MiSalud_VortexIT_Build_021.zip
chmod +x apply_build_021.sh
./apply_build_021.sh

Validación:

flutter analyze
flutter test
flutter run -d linux

Prueba funcional:

1. Abrir Evolución clínica.
2. Aplicar un filtro o período, si se desea.
3. Pulsar el ícono PDF.
4. Probar "Imprimir o guardar".
5. Probar "Guardar archivo PDF" y elegir ubicación.
6. Probar "Compartir PDF".
