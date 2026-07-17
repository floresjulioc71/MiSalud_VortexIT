import 'dart:io';

import 'package:flutter/material.dart';

import '../models/medical_study.dart';
import '../services/medical_study_file_service.dart';

class MedicalStudyViewScreen extends StatelessWidget {
  final MedicalStudy item;

  const MedicalStudyViewScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _InfoCard(item: item),
          const SizedBox(height: 16),
          Text(
            'Archivos adjuntos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (item.attachments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Este estudio no tiene archivos adjuntos.'),
              ),
            )
          else
            ...item.attachments.map(
              (MedicalStudyAttachment attachment) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (attachment.isImage &&
                        File(attachment.path).existsSync())
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.file(
                          File(attachment.path),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ListTile(
                      leading: Icon(
                        attachment.isPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                      ),
                      title: Text(attachment.name),
                      subtitle: Text(_fileSize(attachment.sizeBytes)),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => MedicalStudyFileService.open(attachment),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _InfoCard extends StatelessWidget {
  final MedicalStudy item;

  const _InfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[
      _row(Icons.category_outlined, 'Tipo', item.type),
      _row(Icons.calendar_month_outlined, 'Fecha', _date(item.studyDate)),
      _row(Icons.flag_outlined, 'Estado', item.status.label),
    ];
    if (item.medicalCenter.isNotEmpty) {
      rows.add(
        _row(
          Icons.local_hospital_outlined,
          'Centro médico',
          item.medicalCenter,
        ),
      );
    }
    if (item.professional.isNotEmpty) {
      rows.add(
        _row(Icons.medical_services_outlined, 'Profesional', item.professional),
      );
    }
    if (item.result.isNotEmpty) {
      rows.add(_row(Icons.fact_check_outlined, 'Resultado', item.result));
    }
    if (item.notes.isNotEmpty) {
      rows.add(_row(Icons.notes_outlined, 'Observaciones', item.notes));
    }
    if (item.nextCheckDate != null) {
      rows.add(
        _row(
          Icons.event_repeat_outlined,
          'Próximo control',
          _date(item.nextCheckDate!),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: rows),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
