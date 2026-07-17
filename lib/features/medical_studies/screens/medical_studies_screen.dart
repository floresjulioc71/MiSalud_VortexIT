import 'package:flutter/material.dart';

import '../models/medical_study.dart';
import '../services/medical_study_file_service.dart';
import '../services/medical_study_storage_service.dart';
import 'medical_study_form_screen.dart';
import 'medical_study_view_screen.dart';

class MedicalStudiesScreen extends StatefulWidget {
  const MedicalStudiesScreen({super.key});

  @override
  State<MedicalStudiesScreen> createState() => _MedicalStudiesScreenState();
}

class _MedicalStudiesScreenState extends State<MedicalStudiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MedicalStudy> _items = <MedicalStudy>[];
  MedicalStudyStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _reload();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _reload() async {
    final List<MedicalStudy> items =
        await MedicalStudyStorageService.loadItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<MedicalStudy> get _visibleItems {
    final String query = _searchController.text.trim().toLowerCase();
    return _items.where((MedicalStudy item) {
      if (_status != null && item.status != _status) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final String haystack = <String>[
        item.type,
        item.name,
        item.medicalCenter,
        item.professional,
        item.result,
        item.notes,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openEditor([MedicalStudy? item]) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MedicalStudyFormScreen(item: item),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openView(MedicalStudy item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MedicalStudyViewScreen(item: item),
      ),
    );
  }

  Future<void> _delete(MedicalStudy item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar estudio'),
        content: Text('Se eliminará "${item.name}" y sus archivos adjuntos.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    for (final MedicalStudyAttachment attachment in item.attachments) {
      await MedicalStudyFileService.deletePhysicalFile(attachment);
    }
    await MedicalStudyStorageService.delete(item.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final List<MedicalStudy> visible = _visibleItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Estudios Médicos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Buscar estudios, centros o profesionales',
                    leading: const Icon(Icons.search),
                    trailing: _searchController.text.isEmpty
                        ? null
                        : <Widget>[
                            IconButton(
                              tooltip: 'Limpiar',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                  ),
                ),
                SizedBox(
                  height: 54,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _status == null,
                        onSelected: (_) => setState(() => _status = null),
                      ),
                      const SizedBox(width: 8),
                      ...MedicalStudyStatus.values.map(
                        (MedicalStudyStatus value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(value.label),
                            selected: _status == value,
                            onSelected: (_) => setState(() => _status = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(
                          filtered: _items.isNotEmpty,
                          onAdd: () => _openEditor(),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _status = null);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, int index) {
                            final MedicalStudy item = visible[index];
                            return _StudyCard(
                              item: item,
                              onView: () => _openView(item),
                              onEdit: () => _openEditor(item),
                              onDelete: () => _delete(item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final MedicalStudy item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudyCard({
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (item.status) {
      MedicalStudyStatus.pending => Theme.of(context).colorScheme.tertiary,
      MedicalStudyStatus.completed => Theme.of(context).colorScheme.primary,
      MedicalStudyStatus.reported => Theme.of(context).colorScheme.secondary,
    };
    return Card(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.15),
                foregroundColor: statusColor,
                child: const Icon(Icons.biotech_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${item.type} • ${_date(item.studyDate)}'),
                    if (item.medicalCenter.isNotEmpty) Text(item.medicalCenter),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        Chip(
                          label: Text(item.status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (item.attachments.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.attach_file, size: 16),
                            label: Text(
                              '${item.attachments.length} archivo'
                              '${item.attachments.length == 1 ? '' : 's'}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  switch (value) {
                    case 'view':
                      onView();
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem(value: 'view', child: Text('Ver')),
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

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  const _EmptyState({
    required this.filtered,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.biotech_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'No hay estudios que coincidan con los filtros.'
                  : 'Todavía no hay estudios médicos registrados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (filtered)
              OutlinedButton(
                onPressed: onClear,
                child: const Text('Limpiar filtros'),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Agregar estudio'),
              ),
          ],
        ),
      ),
    );
  }
}
