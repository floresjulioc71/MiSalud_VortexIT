import 'package:flutter/material.dart';
import '../models/clinical_document.dart';

class ClinicalDocumentCard extends StatelessWidget {
  final ClinicalDocument document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ClinicalDocumentCard({
    super.key,
    required this.document,
    required this.onEdit,
    required this.onDelete,
  });

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final List<String> details = <String>[
      document.type.label,
      _date(document.documentDate),
      if (document.professional.trim().isNotEmpty) document.professional,
      if (document.institution.trim().isNotEmpty) document.institution,
    ];
    final IconData icon = document.isPdf
        ? Icons.picture_as_pdf_outlined
        : document.isImage
        ? Icons.image_outlined
        : Icons.description_outlined;
    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                child: Icon(document.hasFile ? icon : Icons.folder_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(details.join(' • ')),
                    if (document.fileName.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        document.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (document.notes.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        document.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
