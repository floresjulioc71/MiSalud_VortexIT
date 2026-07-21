import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PdfReportService {
  const PdfReportService._();

  static Future<Directory> reportsDirectory() async {
    final Directory baseDirectory = await getApplicationDocumentsDirectory();

    final Directory reportsDirectory = Directory(
      '${baseDirectory.path}/reports',
    );

    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    return reportsDirectory;
  }

  static String sanitizeFileName(String value) {
    return value
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  static Future<File> createOutputFile({required String patientName}) async {
    final Directory directory = await reportsDirectory();

    final DateTime now = DateTime.now();

    final String timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final String filename =
        'MiSalud_${sanitizeFileName(patientName)}_$timestamp.pdf';

    return File('${directory.path}/$filename');
  }
}
