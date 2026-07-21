import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../family/services/family_storage_service.dart';
import '../models/study_item.dart';
import 'study_file_service.dart';
import 'study_storage_service.dart';

class StudyBackupService {
  StudyBackupService._();

  static Future<File> exportBackup() async {
    final List<StudyItem> studies = StudyStorageService.loadItems();
    final Directory temp = await getTemporaryDirectory();

    final Directory work = Directory(
      p.join(
        temp.path,
        'misalud_studies_backup_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    await work.create(recursive: true);

    final Directory filesDirectory = Directory(p.join(work.path, 'files'));

    if (!await filesDirectory.exists()) {
      await filesDirectory.create(recursive: true);
    }

    final List<Map<String, dynamic>> manifest = <Map<String, dynamic>>[];

    for (final StudyItem study in studies) {
      String? backupAttachmentName;
      final String? path = study.attachmentPath;

      if (path != null && File(path).existsSync()) {
        backupAttachmentName = '${study.id}_${p.basename(path)}';

        await File(
          path,
        ).copy(p.join(filesDirectory.path, backupAttachmentName));
      }

      final Map<String, dynamic> map = study.toMap();
      map['backupAttachmentName'] = backupAttachmentName;
      manifest.add(map);
    }

    await File(p.join(work.path, 'manifest.json')).writeAsString(
      jsonEncode(<String, dynamic>{
        'version': 1,
        'memberId': FamilyStorageService.activeMemberId,
        'memberName': FamilyStorageService.activeMember.name,
        'studies': manifest,
      }),
    );

    final Directory documents = await getApplicationDocumentsDirectory();

    final Directory backups = Directory(
      p.join(documents.path, 'MiSalud_VortexIT', 'backups'),
    );

    if (!await backups.exists()) {
      await backups.create(recursive: true);
    }

    final File zipFile = File(
      p.join(
        backups.path,
        'estudios_${FamilyStorageService.activeMemberId}_${DateTime.now().millisecondsSinceEpoch}.zip',
      ),
    );

    final ZipFileEncoder encoder = ZipFileEncoder();

    encoder.create(zipFile.path);
    await encoder.addDirectory(work);
    await encoder.close();

    await work.delete(recursive: true);

    return zipFile;
  }

  static Future<int> importBackup() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['zip'],
      allowMultiple: false,
    );

    final String? selectedPath = result?.files.single.path;

    if (selectedPath == null || selectedPath.isEmpty) {
      return 0;
    }

    final Directory temp = await getTemporaryDirectory();

    final Directory work = Directory(
      p.join(
        temp.path,
        'misalud_studies_restore_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    await work.create(recursive: true);

    final InputFileStream input = InputFileStream(selectedPath);
    final Archive archive = ZipDecoder().decodeStream(input);

    extractArchiveToDisk(archive, work.path);

    await input.close();

    File? manifestFile;

    await for (final FileSystemEntity entity in work.list(recursive: true)) {
      if (entity is File && p.basename(entity.path) == 'manifest.json') {
        manifestFile = entity;
        break;
      }
    }

    if (manifestFile == null) {
      await work.delete(recursive: true);

      throw const FormatException(
        'El respaldo no contiene un manifiesto válido.',
      );
    }

    final dynamic decoded = jsonDecode(await manifestFile.readAsString());

    if (decoded is! Map<String, dynamic>) {
      await work.delete(recursive: true);

      throw const FormatException('Respaldo inválido.');
    }

    final dynamic rawStudies = decoded['studies'];

    if (rawStudies is! List<dynamic>) {
      await work.delete(recursive: true);

      throw const FormatException('Respaldo sin estudios.');
    }

    final Directory targetDirectory =
        await StudyFileService.memberStudyDirectory();

    final List<StudyItem> restored = <StudyItem>[];

    for (final dynamic raw in rawStudies) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final String? backupAttachmentName =
          raw['backupAttachmentName'] as String?;

      StudyItem study = StudyItem.fromMap(raw);

      if (backupAttachmentName != null) {
        File? source;

        await for (final FileSystemEntity entity in work.list(
          recursive: true,
        )) {
          if (entity is File &&
              p.basename(entity.path) == backupAttachmentName) {
            source = entity;
            break;
          }
        }

        if (source != null) {
          final String destination = p.join(
            targetDirectory.path,
            '${DateTime.now().microsecondsSinceEpoch}_${p.basename(source.path)}',
          );

          await source.copy(destination);

          study = study.copyWith(
            attachmentPath: destination,
            attachmentType: StudyFileService.typeFromPath(destination),
          );
        }
      }

      restored.add(study);
    }

    await StudyStorageService.saveItems(restored);
    await work.delete(recursive: true);

    return restored.length;
  }
}
