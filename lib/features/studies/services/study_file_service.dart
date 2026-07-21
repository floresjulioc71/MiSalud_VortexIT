import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../family/services/family_storage_service.dart';
import '../models/study_item.dart';

class StudyAttachmentResult {
  final String storedPath;
  final String originalName;
  final StudyAttachmentType type;

  const StudyAttachmentResult({
    required this.storedPath,
    required this.originalName,
    required this.type,
  });
}

class StudyFileService {
  StudyFileService._();

  static final ImagePicker _imagePicker = ImagePicker();

  static Future<StudyAttachmentResult?> pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: false,
    );

    final String? path = result?.files.single.path;

    if (path == null || path.isEmpty) {
      return null;
    }

    return _storeExternalFile(
      sourcePath: path,
      originalName: result!.files.single.name,
    );
  }

  static Future<StudyAttachmentResult?> pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );

    if (image == null) {
      return null;
    }

    return _storeExternalFile(
      sourcePath: image.path,
      originalName: p.basename(image.path),
    );
  }

  static Future<StudyAttachmentResult?> takePhoto() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      throw UnsupportedError(
        'La captura con cámara se prueba en Android o iOS.',
      );
    }

    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );

    if (image == null) {
      return null;
    }

    return _storeExternalFile(
      sourcePath: image.path,
      originalName: p.basename(image.path),
    );
  }

  static Future<void> deleteAttachment(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    final File file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<Directory> memberStudyDirectory() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();

    final Directory directory = Directory(
      p.join(
        appDirectory.path,
        'MiSalud_VortexIT',
        'studies',
        FamilyStorageService.activeMemberId,
      ),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static StudyAttachmentType typeFromPath(String path) {
    final String extension = p.extension(path).toLowerCase();

    if (extension == '.pdf') {
      return StudyAttachmentType.pdf;
    }

    if (<String>['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      return StudyAttachmentType.image;
    }

    return StudyAttachmentType.none;
  }

  static Future<StudyAttachmentResult> _storeExternalFile({
    required String sourcePath,
    required String originalName,
  }) async {
    final StudyAttachmentType type = typeFromPath(sourcePath);

    if (type == StudyAttachmentType.none) {
      throw const FormatException(
        'Solo se admiten archivos PDF, JPG, PNG y WEBP.',
      );
    }

    final Directory directory = await memberStudyDirectory();
    final String extension = p.extension(originalName).toLowerCase();

    final String safeBaseName = p
        .basenameWithoutExtension(originalName)
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');

    final String fileName =
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${safeBaseName.isEmpty ? 'estudio' : safeBaseName}'
        '$extension';

    final String destinationPath = p.join(directory.path, fileName);

    await File(sourcePath).copy(destinationPath);

    return StudyAttachmentResult(
      storedPath: destinationPath,
      originalName: originalName,
      type: type,
    );
  }
}
