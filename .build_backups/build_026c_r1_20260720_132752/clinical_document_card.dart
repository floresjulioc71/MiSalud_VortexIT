import 'package:flutter/material.dart';

import '../models/clinical_document.dart';

class ClinicalDocumentCard extends StatelessWidget {
  final ClinicalDocument document;
  final VoidCallback onOpen;
  final VoidCallback? onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClinicalDocumentCard({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  String _formattedDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  IconData get _fileIcon {
    if (document.isPdf) {
      return Icons.picture_as_pdf_outlined;
    }

    if (document.isImage) {
      return Icons.image_outlined;
    }

    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> details = <String>[
      document.type.label,
      _formattedDate(document.documentDate),
      if (document.professional.trim().isNotEmpty) document.professional,
      if (document.institution.trim().isNotEmpty) document.institution,
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                child: Icon(
                  document.hasFile ? _fileIcon : Icons.folder_outlined,
                ),
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
                    if (document.fileName.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.attach_file, size: 17),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              document.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (document.notes.trim().isNotEmpty) ...<Widget>[
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
                onSelected: (String value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                    case 'share':
                      onShare?.call();
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'open',
                      child: ListTile(
                        leading: Icon(Icons.visibility_outlined),
                        title: Text('Ver'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (document.hasFile)
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('Compartir'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Eliminar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
