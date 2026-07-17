import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class StoredClinicalFile {
  final String fileName;
  final String filePath;
  final String mimeType;

  const StoredClinicalFile({
    required this.fileName,
    required this.filePath,
    required this.mimeType,
  });
}

class ClinicalDocumentFileService {
  static const XTypeGroup _allowedFiles = XTypeGroup(
    label: 'Documentos clínicos',
    extensions: <String>['pdf', 'jpg', 'jpeg', 'png', 'webp'],
  );

  static Future<StoredClinicalFile?> pickAndStore({
    required String memberId,
  }) async {
    final XFile? selectedFile = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_allowedFiles],
    );

    if (selectedFile == null) {
      return null;
    }

    return storeFile(
      sourcePath: selectedFile.path,
      originalName: selectedFile.name,
      memberId: memberId,
    );
  }

  static Future<StoredClinicalFile> storeFile({
    required String sourcePath,
    required String originalName,
    required String memberId,
  }) async {
    final File sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'No se encontró el archivo seleccionado.',
        sourcePath,
      );
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory destinationDirectory = Directory(
      path.join(
        appDirectory.path,
        'MiSalud_VortexIT',
        'clinical_documents',
        _safeSegment(memberId),
      ),
    );

    await destinationDirectory.create(recursive: true);

    final String extension = path.extension(originalName).toLowerCase();
    final String baseName = _safeBaseName(
      path.basenameWithoutExtension(originalName),
    );
    final String storedName =
        '${DateTime.now().microsecondsSinceEpoch}_$baseName$extension';
    final String destinationPath = path.join(
      destinationDirectory.path,
      storedName,
    );

    await sourceFile.copy(destinationPath);

    return StoredClinicalFile(
      fileName: originalName,
      filePath: destinationPath,
      mimeType: _mimeType(extension),
    );
  }

  static Future<void> deleteStoredFile(String filePath) async {
    if (filePath.trim().isEmpty) {
      return;
    }

    final File file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<bool> exists(String filePath) async {
    if (filePath.trim().isEmpty) {
      return false;
    }

    return File(filePath).exists();
  }

  static String _safeSegment(String value) {
    final String cleaned = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    if (cleaned.isEmpty) {
      return 'default';
    }

    return cleaned;
  }

  static String _safeBaseName(String value) {
    final String cleaned = value.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    if (cleaned.isEmpty) {
      return 'documento';
    }

    return cleaned;
  }

  static String _mimeType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
