import 'package:flutter/material.dart';

import '../models/clinical_document.dart';
import '../services/clinical_document_file_service.dart';
import '../services/clinical_document_storage_service.dart';
import '../widgets/clinical_document_card.dart';
import 'clinical_document_form_screen.dart';
import 'clinical_document_view_screen.dart';

class ClinicalDocumentsScreen extends StatefulWidget {
  final String memberId;

  const ClinicalDocumentsScreen({super.key, this.memberId = 'default'});

  @override
  State<ClinicalDocumentsScreen> createState() =>
      _ClinicalDocumentsScreenState();
}

class _ClinicalDocumentsScreenState extends State<ClinicalDocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ClinicalDocument> _documents = <ClinicalDocument>[];
  ClinicalDocumentType? _selectedType;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    await ClinicalDocumentStorageService.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _documents = ClinicalDocumentStorageService.loadItems();
      _loading = false;
    });
  }

  List<ClinicalDocument> get _filteredDocuments {
    final String query = _searchController.text.trim().toLowerCase();

    return _documents.where((ClinicalDocument document) {
      final bool matchesType =
          _selectedType == null || document.type == _selectedType;

      final bool matchesSearch =
          query.isEmpty ||
          document.title.toLowerCase().contains(query) ||
          document.professional.toLowerCase().contains(query) ||
          document.institution.toLowerCase().contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  Future<void> _openForm([ClinicalDocument? document]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return ClinicalDocumentFormScreen(
            memberId: widget.memberId,
            document: document,
          );
        },
      ),
    );

    if (changed == true) {
      await _loadDocuments();
    }
  }

  Future<void> _openDocument(ClinicalDocument document) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext viewContext) {
          return ClinicalDocumentViewScreen(
            document: document,
            onEdit: () async {
              Navigator.of(viewContext).pop();
              await _openForm(document);
            },
          );
        },
      ),
    );
  }

  Future<void> _shareDocument(ClinicalDocument document) async {
    try {
      await ClinicalDocumentFileService.shareStoredFile(
        filePath: document.filePath,
        title: document.title,
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir el archivo: $error')),
      );
    }
  }

  Future<void> _deleteDocument(ClinicalDocument document) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar documento'),
          content: Text(
            '¿Querés eliminar "${document.title}"?\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ClinicalDocumentStorageService.deleteItem(document.id);
    await ClinicalDocumentFileService.deleteStoredFile(document.filePath);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Documento eliminado.')));

    await _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    final List<ClinicalDocument> filtered = _filteredDocuments;

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos clínicos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: <Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar por título, profesional o institución',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ClinicalDocumentType?>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<ClinicalDocumentType?>>[
                      const DropdownMenuItem<ClinicalDocumentType?>(
                        value: null,
                        child: Text('Todos los documentos'),
                      ),
                      ...ClinicalDocumentType.values.map((
                        ClinicalDocumentType type,
                      ) {
                        return DropdownMenuItem<ClinicalDocumentType?>(
                          value: type,
                          child: Text(type.label),
                        );
                      }),
                    ],
                    onChanged: (ClinicalDocumentType? value) {
                      setState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_documents.isEmpty)
                    const _EmptyState(
                      title: 'Todavía no hay documentos',
                      message:
                          'Agregá recetas, órdenes, certificados, altas y otros documentos clínicos.',
                    )
                  else if (filtered.isEmpty)
                    const _EmptyState(
                      title: 'No encontramos resultados',
                      message:
                          'Probá con otra búsqueda o seleccioná una categoría diferente.',
                    )
                  else
                    ...filtered.map((ClinicalDocument document) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClinicalDocumentCard(
                          document: document,
                          onOpen: () => _openDocument(document),
                          onShare: document.hasFile
                              ? () => _shareDocument(document)
                              : null,
                          onEdit: () => _openForm(document),
                          onDelete: () => _deleteDocument(document),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.folder_open_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
