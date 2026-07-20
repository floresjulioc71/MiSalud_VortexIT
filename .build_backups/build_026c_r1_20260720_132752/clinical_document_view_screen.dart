import 'dart:io';

import 'package:flutter/material.dart';

import '../models/clinical_document.dart';
import '../services/clinical_document_file_service.dart';

class ClinicalDocumentViewScreen extends StatelessWidget {
  final ClinicalDocument document;
  final VoidCallback? onEdit;

  const ClinicalDocumentViewScreen({
    super.key,
    required this.document,
    this.onEdit,
  });

  Future<void> _runFileAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la acción: $error')),
      );
    }
  }

  String _formattedDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool imageAvailable =
        document.isImage && File(document.filePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: <Widget>[
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (imageAvailable)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(document.filePath),
                height: 280,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Categoría',
                    value: document.type.label,
                  ),
                  _InfoRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Fecha',
                    value: _formattedDate(document.documentDate),
                  ),
                  if (document.professional.trim().isNotEmpty)
                    _InfoRow(
                      icon: Icons.medical_services_outlined,
                      label: 'Profesional',
                      value: document.professional,
                    ),
                  if (document.institution.trim().isNotEmpty)
                    _InfoRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Institución',
                      value: document.institution,
                    ),
                  if (document.notes.trim().isNotEmpty)
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Observaciones',
                      value: document.notes,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Archivo adjunto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (!document.hasFile)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Este registro no tiene un archivo adjunto.'),
              ),
            )
          else
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: Icon(
                      document.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(document.fileName),
                    subtitle: Text(document.mimeType),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _runFileAction(
                              context,
                              () => ClinicalDocumentFileService.openStoredFile(
                                document.filePath,
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Abrir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _runFileAction(
                              context,
                              () => ClinicalDocumentFileService.shareStoredFile(
                                filePath: document.filePath,
                                title: document.title,
                              ),
                            ),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
