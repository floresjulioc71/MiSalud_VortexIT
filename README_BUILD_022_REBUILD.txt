MiSalud_VortexIT - Build 022 reconstruido

Corrige los problemas de los paquetes anteriores:
- elimina la carpeta residual files/;
- instala realmente lib/features/health_controls/;
- detecta automáticamente el nombre del paquete desde pubspec.yaml;
- reemplaza el Dashboard usando la estructura real del proyecto;
- conserva una copia del Dashboard anterior;
- separa los controles por integrante familiar.

Incluye:
- alta, edición y eliminación de controles;
- fecha y hora;
- presión arterial;
- frecuencia cardíaca;
- SpO2;
- temperatura;
- peso;
- glucemia;
- observaciones;
- filtros de 30 días, 90 días, 1 año y rango personalizado;
- exportación PDF de los registros filtrados;
- imprimir/guardar, guardar archivo y compartir PDF.

Aplicación:
  unzip -o MiSalud_VortexIT_Build_022_REBUILD.zip
  chmod +x apply_build_022_rebuild.sh
  ./apply_build_022_rebuild.sh
