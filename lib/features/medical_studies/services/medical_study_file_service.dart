import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/medical_study.dart';

class MedicalStudyFileService {
  static const Uuid _uuid = Uuid();

  static Future<List<MedicalStudyAttachment>> pickAndCopyFiles() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Documentos médicos',
      extensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    );
    final List<XFile> selected = await openFiles(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );
    if (selected.isEmpty) {
      return <MedicalStudyAttachment>[];
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory targetDirectory = Directory(
      path.join(appDirectory.path, 'MiSalud_VortexIT', 'medical_studies'),
    );
    await targetDirectory.create(recursive: true);

    final List<MedicalStudyAttachment> result = <MedicalStudyAttachment>[];
    for (final XFile source in selected) {
      final String extension = path.extension(source.name).toLowerCase();
      final String id = _uuid.v4();
      final String targetPath = path.join(
        targetDirectory.path,
        '$id$extension',
      );
      final File copied = await File(source.path).copy(targetPath);
      result.add(
        MedicalStudyAttachment(
          id: id,
          name: source.name,
          path: copied.path,
          mimeType: source.mimeType ?? _mimeFromExtension(extension),
          sizeBytes: await copied.length(),
        ),
      );
    }
    return result;
  }

  static Future<void> open(MedicalStudyAttachment attachment) async {
    await OpenFilex.open(attachment.path);
  }

  static Future<void> deletePhysicalFile(
    MedicalStudyAttachment attachment,
  ) async {
    final File file = File(attachment.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _mimeFromExtension(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
