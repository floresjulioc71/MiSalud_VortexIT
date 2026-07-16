import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../models/study_item.dart';

class StudyShareService {
  StudyShareService._();

  static Future<void> share(StudyItem study) async {
    final String? path = study.attachmentPath;

    if (path == null || path.isEmpty || !File(path).existsSync()) {
      throw StateError('El estudio no tiene un archivo disponible.');
    }

    if (Platform.isLinux) {
      throw UnsupportedError(
        'Linux no permite compartir archivos mediante share_plus. '
        'Esta función debe probarse en Android o Windows.',
      );
    }

    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path)],
        text: 'Estudio médico: ${study.name}',
        subject: study.name,
        title: study.name,
      ),
    );
  }
}
