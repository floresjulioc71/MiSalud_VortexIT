import 'package:flutter/material.dart';

import '../models/health_control.dart';
import '../services/health_control_pdf_service.dart';
import '../services/health_control_storage_service.dart';
import 'health_control_form_screen.dart';
import 'health_controls_evolution_screen.dart';

class HealthControlsScreen extends StatefulWidget {
  const HealthControlsScreen({super.key});

  @override
  State<HealthControlsScreen> createState() => _HealthControlsScreenState();
}

class _HealthControlsScreenState extends State<HealthControlsScreen> {
  List<HealthControl> _items = <HealthControl>[];
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<HealthControl> items = HealthControlStorageService.loadItems();
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<HealthControl> get _visibleItems => _items.where((HealthControl item) {
    final DateTime day = DateTime(
      item.recordedAt.year,
      item.recordedAt.month,
      item.recordedAt.day,
    );
    if (_dateFrom != null && day.isBefore(_dateFrom!)) {
      return false;
    }
    if (_dateTo != null && day.isAfter(_dateTo!)) {
      return false;
    }
    return true;
  }).toList();

  Future<void> _openEditor([HealthControl? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HealthControlFormScreen(item: item),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openEvolution() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HealthControlsEvolutionScreen(
          initialDateFrom: _dateFrom,
          initialDateTo: _dateTo,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _delete(HealthControl item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar control'),
        content: const Text('Esta acción no se puede deshacer.'),
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
    await HealthControlStorageService.deleteItem(item.id);
    await _reload();
  }

  void _setQuickRange(int? days) {
    setState(() {
      if (days == null) {
        _dateFrom = null;
        _dateTo = null;
      } else {
        final DateTime now = DateTime.now();
        _dateTo = DateTime(now.year, now.month, now.day);
        _dateFrom = _dateTo!.subtract(Duration(days: days - 1));
      }
    });
  }

  Future<void> _selectCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range == null) {
      return;
    }
    setState(() {
      _dateFrom = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _dateTo = DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  Future<void> _export(String action) async {
    final List<HealthControl> items = _visibleItems;
    if (items.isEmpty || _exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      if (action == 'print') {
        await HealthControlPdfService.printOrSave(
          items: items,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
      } else if (action == 'save') {
        final String? path = await HealthControlPdfService.saveFile(
          items: items,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
        if (path != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF guardado en: $path')));
        }
      } else if (action == 'share') {
        await HealthControlPdfService.share(
          items: items,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible generar el PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<HealthControl> visible = _visibleItems;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controles de Salud'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ver evolución',
            onPressed: _openEvolution,
            icon: const Icon(Icons.insights_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Exportar PDF',
            enabled: visible.isNotEmpty && !_exporting,
            onSelected: _export,
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print_outlined),
                  title: Text('Imprimir o guardar'),
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save_alt_outlined),
                  title: Text('Guardar archivo PDF'),
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Compartir PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                _FilterBar(
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                  onAll: () => _setQuickRange(null),
                  on30: () => _setQuickRange(30),
                  on90: () => _setQuickRange(90),
                  onYear: () => _setQuickRange(365),
                  onCustom: _selectCustomRange,
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(
                          hasFilters: _dateFrom != null || _dateTo != null,
                          onAdd: () => _openEditor(),
                          onClear: () => _setQuickRange(null),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, int index) => _ControlCard(
                            item: visible[index],
                            onEdit: () => _openEditor(visible[index]),
                            onDelete: () => _delete(visible[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback onAll;
  final VoidCallback on30;
  final VoidCallback on90;
  final VoidCallback onYear;
  final VoidCallback onCustom;

  const _FilterBar({
    required this.dateFrom,
    required this.dateTo,
    required this.onAll,
    required this.on30,
    required this.on90,
    required this.onYear,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  ActionChip(label: const Text('Todos'), onPressed: onAll),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('30 días'), onPressed: on30),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('90 días'), onPressed: on90),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('1 año'), onPressed: onYear),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_outlined, size: 18),
                    label: const Text('Rango'),
                    onPressed: onCustom,
                  ),
                ],
              ),
            ),
            if (dateFrom != null || dateTo != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Período: ${dateFrom == null ? 'inicio' : _date(dateFrom!)} al '
                '${dateTo == null ? 'hoy' : _date(dateTo!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ControlCard extends StatelessWidget {
  final HealthControl item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ControlCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> values = <Widget>[];
    void add(IconData icon, String text) => values.add(
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );

    if (item.systolicPressure != null || item.diastolicPressure != null) {
      add(
        Icons.monitor_heart_outlined,
        '${item.systolicPressure ?? '-'} / ${item.diastolicPressure ?? '-'} mmHg',
      );
    }
    if (item.heartRate != null) {
      add(Icons.favorite_outline, '${item.heartRate} lpm');
    }
    if (item.oxygenSaturation != null) {
      add(Icons.air, '${item.oxygenSaturation} % SpO₂');
    }
    if (item.temperature != null) {
      add(
        Icons.thermostat_outlined,
        '${item.temperature!.toStringAsFixed(1)} °C',
      );
    }
    if (item.weight != null) {
      add(
        Icons.monitor_weight_outlined,
        '${item.weight!.toStringAsFixed(1)} kg',
      );
    }
    if (item.bloodGlucose != null) {
      add(
        Icons.water_drop_outlined,
        '${item.bloodGlucose!.toStringAsFixed(0)} mg/dL',
      );
    }
    if (item.notes.isNotEmpty) {
      add(Icons.notes_outlined, item.notes);
    }

    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _dateTime(item.recordedAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      if (value == 'edit') {
                        onEdit();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              ...values,
            ],
          ),
        ),
      ),
    );
  }

  static String _dateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  const _EmptyState({
    required this.hasFilters,
    required this.onAdd,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.monitor_heart_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No hay controles en el rango seleccionado.'
                : 'Todavía no hay controles registrados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (hasFilters)
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Limpiar rango'),
            )
          else
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar control'),
            ),
        ],
      ),
    ),
  );
}
