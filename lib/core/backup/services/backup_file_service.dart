import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../utils/backup_constants.dart';

class BackupFileService {
  const BackupFileService();

  Future<File?> saveBackup({
    required Map<String, dynamic> backup,
    required String defaultFileName,
  }) async {
    final String fileName =
        defaultFileName.endsWith('.${BackupConstants.fileExtension}')
        ? defaultFileName
        : '$defaultFileName.${BackupConstants.fileExtension}';

    final String? selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar respaldo de MiSalud',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[BackupConstants.fileExtension],
    );

    if (selectedPath == null) {
      return null;
    }

    final String finalPath =
        selectedPath.endsWith('.${BackupConstants.fileExtension}')
        ? selectedPath
        : '$selectedPath.${BackupConstants.fileExtension}';

    final String jsonContent = const JsonEncoder.withIndent(
      '  ',
    ).convert(backup);

    final File file = File(finalPath);

    await file.writeAsString(jsonContent, flush: true);

    return file;
  }

  Future<Map<String, dynamic>?> openBackup() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Seleccionar respaldo de MiSalud',
      type: FileType.custom,
      allowedExtensions: <String>[BackupConstants.fileExtension],
      allowMultiple: false,
    );

    if (result == null) {
      return null;
    }

    final String? path = result.files.single.path;

    if (path == null) {
      throw const FileSystemException(
        'No fue posible obtener la ubicación del respaldo.',
      );
    }

    final File file = File(path);

    if (!await file.exists()) {
      throw FileSystemException(
        'El archivo de respaldo seleccionado no existe.',
        path,
      );
    }

    final String jsonContent = await file.readAsString();
    final Object? decoded = jsonDecode(jsonContent);

    if (decoded is! Map) {
      throw const FormatException(
        'El archivo seleccionado no contiene un respaldo válido.',
      );
    }

    return Map<String, dynamic>.from(decoded);
  }
}
