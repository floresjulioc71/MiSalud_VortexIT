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
    final source = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[_allowedFiles],
    );
    if (source == null) return null;
    return storeFile(
      sourcePath: source.path,
      originalName: source.name,
      memberId: memberId,
    );
  }

  static Future<StoredClinicalFile> storeFile({
    required String sourcePath,
    required String originalName,
    required String memberId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists())
      throw FileSystemException(
        'No se encontró el archivo seleccionado.',
        sourcePath,
      );
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      path.join(
        appDir.path,
        'MiSalud_VortexIT',
        'clinical_documents',
        _safe(memberId),
      ),
    );
    await dir.create(recursive: true);
    final extension = path.extension(originalName).toLowerCase();
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${_safe(path.basenameWithoutExtension(originalName))}$extension';
    final destination = path.join(dir.path, name);
    await source.copy(destination);
    return StoredClinicalFile(
      fileName: originalName,
      filePath: destination,
      mimeType: _mime(extension),
    );
  }

  static Future<void> deleteStoredFile(String filePath) async {
    if (filePath.trim().isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }

  static Future<bool> exists(String filePath) async =>
      filePath.trim().isNotEmpty && File(filePath).exists();
  static String _safe(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return cleaned.isEmpty ? 'default' : cleaned;
  }

  static String _mime(String extension) {
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
