MiSalud_VortexIT - Build 023
Gráficos y evolución de controles de salud

INSTALACIÓN
1. Descomprimir este ZIP en la raíz del proyecto Flutter.
2. Ejecutar:
   chmod +x apply_build_023.sh
   ./apply_build_023.sh

FUNCIONALIDADES
- Nueva pantalla Evolución, accesible desde el icono de gráfico en Controles.
- Gráficos de líneas para peso, presión sistólica, presión diastólica,
  glucemia, frecuencia cardíaca, saturación y temperatura.
- Filtros: todos, 30 días, 90 días, un año y rango personalizado.
- Estadísticas: mínimo, máximo, promedio, último valor y cantidad.
- Datos separados por integrante mediante el almacenamiento existente.
- Diseño adaptable para Android, Linux y Windows.
- Pruebas unitarias para los cálculos estadísticos.

El instalador usa archivos .src, los copia a su ubicación final y elimina
build_023_payload para evitar que flutter analyze inspeccione archivos auxiliares.
