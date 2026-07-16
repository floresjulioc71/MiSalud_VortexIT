import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/constants/app_spacing.dart';
import '../models/study_item.dart';

class StudyViewerScreen extends StatelessWidget {
  final StudyItem study;

  const StudyViewerScreen({super.key, required this.study});

  @override
  Widget build(BuildContext context) {
    final String? path = study.attachmentPath;

    return Scaffold(
      appBar: AppBar(title: Text(study.attachmentOriginalName ?? study.name)),
      body: path == null || !File(path).existsSync()
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.large),
                child: Text(
                  'El archivo adjunto no está disponible.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _buildViewer(path),
    );
  }

  Widget _buildViewer(String path) {
    switch (study.attachmentType) {
      case StudyAttachmentType.pdf:
        return PdfViewer.file(path);
      case StudyAttachmentType.image:
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Text('No fue posible mostrar la imagen.');
              },
            ),
          ),
        );
      case StudyAttachmentType.none:
        return const Center(child: Text('Tipo de archivo no compatible.'));
    }
  }
}
