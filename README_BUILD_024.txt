MiSalud_VortexIT - Build 024
Estudios Médicos y documentos adjuntos

INSTALACIÓN

1. Copiar el ZIP a la raíz del proyecto.
2. Ejecutar:

   unzip -o MiSalud_VortexIT_Build_024.zip
   chmod +x apply_build_024.sh
   ./apply_build_024.sh

3. Validar:

   flutter analyze
   flutter test
   flutter run -d linux

FUNCIONES

- CRUD completo de estudios médicos.
- Estados Pendiente, Realizado e Informado.
- Búsqueda y filtros.
- Adjuntos múltiples PDF, JPG, JPEG y PNG.
- Copia de archivos al almacenamiento privado de la aplicación.
- Vista previa de imágenes.
- Apertura de documentos con la aplicación predeterminada.
- Almacenamiento separado mediante el identificador activo del grupo familiar.
- Respaldo previo a la instalación.
- Acceso automático desde Controles de Salud.
