import 'package:flutter/material.dart';

import '../models/vaccine_record.dart';
import '../services/vaccine_file_service.dart';
import '../services/vaccine_storage_service.dart';
import 'vaccine_form_screen.dart';
import 'vaccine_view_screen.dart';

class VaccinesScreen extends StatefulWidget {
  const VaccinesScreen({super.key});

  @override
  State<VaccinesScreen> createState() => _VaccinesScreenState();
}

class _VaccinesScreenState extends State<VaccinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<VaccineRecord> _items = <VaccineRecord>[];
  VaccineScheduleStatus? _status;
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
    final List<VaccineRecord> items = await VaccineStorageService.loadItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<VaccineRecord> get _visibleItems {
    final String query = _searchController.text.trim().toLowerCase();
    final DateTime now = DateTime.now();
    return _items.where((VaccineRecord item) {
      if (_status != null && item.statusAt(now) != _status) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final String text = <String>[
        item.vaccineName,
        item.preventsDisease,
        item.laboratory,
        item.lotNumber,
        item.vaccinationCenter,
        item.professional,
        item.notes,
        item.statusAt(now).label,
      ].join(' ').toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _openEditor([VaccineRecord? item]) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => VaccineFormScreen(item: item)),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _view(VaccineRecord item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => VaccineViewScreen(item: item)),
    );
  }

  Future<void> _delete(VaccineRecord item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar vacuna'),
        content: Text('Se eliminará "${item.vaccineName}".'),
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
    for (final VaccineAttachment attachment in item.attachments) {
      await VaccineFileService.deletePhysicalFile(attachment);
    }
    await VaccineStorageService.delete(item.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final List<VaccineRecord> visible = _visibleItems;
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas')),
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
                    hintText: 'Buscar vacuna, enfermedad, lote o centro',
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
                        label: const Text('Todas'),
                        selected: _status == null,
                        onSelected: (_) => setState(() => _status = null),
                      ),
                      const SizedBox(width: 8),
                      ...VaccineScheduleStatus.values.map(
                        (VaccineScheduleStatus value) => Padding(
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
                            final VaccineRecord item = visible[index];
                            return _VaccineCard(
                              item: item,
                              onView: () => _view(item),
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

class _VaccineCard extends StatelessWidget {
  final VaccineRecord item;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VaccineCard({
    required this.item,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final VaccineScheduleStatus status = item.statusAt(DateTime.now());
    return Card(
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const CircleAvatar(child: Icon(Icons.vaccines_outlined)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.vaccineName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.preventsDisease.isNotEmpty)
                      Text(item.preventsDisease),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(item.applicationDate)} • '
                      'Dosis ${item.doseNumber}/${item.totalDoses}',
                    ),
                    if (item.nextDoseDate != null)
                      Text('Próxima: ${_date(item.nextDoseDate!)}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        Chip(
                          label: Text(status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                        if (item.attachments.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.attach_file, size: 16),
                            label: Text('${item.attachments.length}'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'view') {
                    onView();
                  } else if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
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
            const Icon(Icons.vaccines_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'No hay vacunas que coincidan con los filtros.'
                  : 'Todavía no hay vacunas registradas.',
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
                label: const Text('Agregar vacuna'),
              ),
          ],
        ),
      ),
    );
  }
}
