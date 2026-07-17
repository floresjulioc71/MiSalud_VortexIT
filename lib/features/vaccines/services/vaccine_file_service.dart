import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/vaccine_item.dart';

class VaccineFileService {
  static const Uuid _uuid = Uuid();

  static Future<List<VaccineAttachment>> pickFiles() async {
    const XTypeGroup group = XTypeGroup(
      label: 'Comprobantes de vacunación',
      extensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    );

    final List<XFile> selected = await openFiles(
      acceptedTypeGroups: <XTypeGroup>[group],
    );

    if (selected.isEmpty) {
      return <VaccineAttachment>[];
    }

    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory destination = Directory(
      path.join(documents.path, 'MiSalud_VortexIT', 'vaccines'),
    );
    await destination.create(recursive: true);

    final List<VaccineAttachment> attachments = <VaccineAttachment>[];

    for (final XFile source in selected) {
      final String id = _uuid.v4();
      final String extension = path.extension(source.name).toLowerCase();
      final File copied = await File(
        source.path,
      ).copy(path.join(destination.path, '$id$extension'));

      attachments.add(
        VaccineAttachment(
          id: id,
          name: source.name,
          path: copied.path,
          mimeType: source.mimeType ?? '',
          sizeBytes: await copied.length(),
        ),
      );
    }

    return attachments;
  }

  static Future<void> openAttachment(VaccineAttachment attachment) async {
    await OpenFilex.open(attachment.path);
  }

  static Future<void> deleteAttachment(VaccineAttachment attachment) async {
    final File file = File(attachment.path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
