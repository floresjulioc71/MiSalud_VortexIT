import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../diagnoses/models/diagnosis_entry.dart';
import '../models/consultation_item.dart';
import '../services/consultation_storage_service.dart';
import '../services/consultation_timeline_pdf_service.dart';
import 'consultation_edit_screen.dart';

enum _PdfAction { print, save, share }

enum _QuickPeriod { all, last30Days, last90Days, lastYear, custom }

class ConsultationTimelineScreen extends StatefulWidget {
  const ConsultationTimelineScreen({super.key});

  @override
  State<ConsultationTimelineScreen> createState() =>
      _ConsultationTimelineScreenState();
}

class _ConsultationTimelineScreenState
    extends State<ConsultationTimelineScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<ConsultationItem> _items = <ConsultationItem>[];
  String? _selectedDoctor;
  String? _selectedDiagnosis;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  _QuickPeriod _quickPeriod = _QuickPeriod.all;
  bool _newestFirst = true;
  final Set<String> _expandedItemIds = <String>{};
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    final List<ConsultationItem> items = ConsultationStorageService.loadItems();

    items.sort(
      (ConsultationItem a, ConsultationItem b) =>
          b.consultationDateTime.compareTo(a.consultationDateTime),
    );

    setState(() {
      _items = items;
    });
  }

  Future<void> _openEditor(ConsultationItem item) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ConsultationEditScreen(item: item),
      ),
    );

    if (changed == true && mounted) {
      _reload();
    }
  }

  List<String> get _doctors {
    final Set<String> values = _items
        .map((ConsultationItem item) => item.doctorNameSnapshot.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    final List<String> result = values.toList()..sort();
    return result;
  }

  List<String> get _diagnoses {
    final Set<String> values = <String>{};

    for (final ConsultationItem item in _items) {
      for (final DiagnosisEntry diagnosis in item.diagnoses) {
        final String description = diagnosis.description.trim();

        if (description.isNotEmpty) {
          values.add(description);
        }
      }
    }

    final List<String> result = values.toList()..sort();
    return result;
  }

  List<ConsultationItem> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();

    final List<ConsultationItem> result = _items.where((ConsultationItem item) {
      if (_selectedDoctor != null &&
          item.doctorNameSnapshot.trim() != _selectedDoctor) {
        return false;
      }

      if (_selectedDiagnosis != null) {
        final bool containsDiagnosis = item.diagnoses.any(
          (DiagnosisEntry diagnosis) =>
              diagnosis.description.trim() == _selectedDiagnosis,
        );

        if (!containsDiagnosis) {
          return false;
        }
      }

      final DateTime consultationDate = DateUtils.dateOnly(
        item.consultationDateTime,
      );

      if (_dateFrom != null &&
          consultationDate.isBefore(DateUtils.dateOnly(_dateFrom!))) {
        return false;
      }

      if (_dateTo != null &&
          consultationDate.isAfter(DateUtils.dateOnly(_dateTo!))) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchableText = <String>[
        item.doctorNameSnapshot,
        item.specialtySnapshot,
        item.reason,
        item.treatment,
        item.prescribedMedication,
        item.requestedStudies,
        item.notes,
        ...item.diagnoses.map(
          (DiagnosisEntry diagnosis) => diagnosis.description,
        ),
      ].join(' ').toLowerCase();

      return searchableText.contains(query);
    }).toList();

    result.sort(
      (ConsultationItem a, ConsultationItem b) => _newestFirst
          ? b.consultationDateTime.compareTo(a.consultationDateTime)
          : a.consultationDateTime.compareTo(b.consultationDateTime),
    );

    return result;
  }

  void _applyQuickPeriod(_QuickPeriod period) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());

    setState(() {
      _quickPeriod = period;

      switch (period) {
        case _QuickPeriod.all:
          _dateFrom = null;
          _dateTo = null;
          return;
        case _QuickPeriod.last30Days:
          _dateFrom = today.subtract(const Duration(days: 29));
          _dateTo = today;
          return;
        case _QuickPeriod.last90Days:
          _dateFrom = today.subtract(const Duration(days: 89));
          _dateTo = today;
          return;
        case _QuickPeriod.lastYear:
          _dateFrom = DateTime(today.year - 1, today.month, today.day);
          _dateTo = today;
          return;
        case _QuickPeriod.custom:
          return;
      }
    });
  }

  Future<void> _selectDateFrom() async {
    final DateTime initialDate = _dateFrom ?? _items.last.consultationDateTime;
    final DateTime firstDate = _items.last.consultationDateTime;
    final DateTime lastDate = _dateTo ?? DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _clampDate(initialDate, firstDate, lastDate),
      firstDate: DateUtils.dateOnly(firstDate),
      lastDate: DateUtils.dateOnly(lastDate),
      helpText: 'Fecha desde',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dateFrom = selected;
      _quickPeriod = _QuickPeriod.custom;
    });
  }

  Future<void> _selectDateTo() async {
    final DateTime initialDate = _dateTo ?? _items.first.consultationDateTime;
    final DateTime firstDate = _dateFrom ?? _items.last.consultationDateTime;
    final DateTime lastDate = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _clampDate(initialDate, firstDate, lastDate),
      firstDate: DateUtils.dateOnly(firstDate),
      lastDate: DateUtils.dateOnly(lastDate),
      helpText: 'Fecha hasta',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dateTo = selected;
      _quickPeriod = _QuickPeriod.custom;
    });
  }

  DateTime _clampDate(DateTime value, DateTime minimum, DateTime maximum) {
    final DateTime date = DateUtils.dateOnly(value);
    final DateTime min = DateUtils.dateOnly(minimum);
    final DateTime max = DateUtils.dateOnly(maximum);

    if (date.isBefore(min)) {
      return min;
    }

    if (date.isAfter(max)) {
      return max;
    }

    return date;
  }

  Future<void> _runPdfAction(_PdfAction action) async {
    final List<ConsultationItem> visibleItems = _filteredItems;

    if (visibleItems.isEmpty || _exportingPdf) {
      return;
    }

    setState(() {
      _exportingPdf = true;
    });

    try {
      final String? savedPath;

      switch (action) {
        case _PdfAction.print:
          await ConsultationTimelinePdfService.printPdf(
            items: visibleItems,
            doctorFilter: _selectedDoctor,
            diagnosisFilter: _selectedDiagnosis,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            searchText: _searchController.text.trim(),
          );
          savedPath = null;
        case _PdfAction.save:
          savedPath = await ConsultationTimelinePdfService.savePdf(
            items: visibleItems,
            doctorFilter: _selectedDoctor,
            diagnosisFilter: _selectedDiagnosis,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            searchText: _searchController.text.trim(),
          );
        case _PdfAction.share:
          await ConsultationTimelinePdfService.sharePdf(
            items: visibleItems,
            doctorFilter: _selectedDoctor,
            diagnosisFilter: _selectedDiagnosis,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            searchText: _searchController.text.trim(),
          );
          savedPath = null;
      }

      if (!mounted || action != _PdfAction.save || savedPath == null) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('PDF guardado en: $savedPath')));
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No fue posible procesar el PDF: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exportingPdf = false;
        });
      }
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      if (_expandedItemIds.contains(itemId)) {
        _expandedItemIds.remove(itemId);
      } else {
        _expandedItemIds.add(itemId);
      }
    });
  }

  void _expandAllVisible() {
    setState(() {
      _expandedItemIds.addAll(
        _filteredItems.map((ConsultationItem item) => item.id),
      );
    });
  }

  void _collapseAllVisible() {
    setState(() {
      _expandedItemIds.removeAll(
        _filteredItems.map((ConsultationItem item) => item.id),
      );
    });
  }

  bool _areAllVisibleExpanded(List<ConsultationItem> visibleItems) {
    return visibleItems.isNotEmpty &&
        visibleItems.every(
          (ConsultationItem item) => _expandedItemIds.contains(item.id),
        );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedDoctor = null;
      _selectedDiagnosis = null;
      _dateFrom = null;
      _dateTo = null;
      _quickPeriod = _QuickPeriod.all;
      _newestFirst = true;
    });
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedDoctor != null ||
      _selectedDiagnosis != null ||
      _dateFrom != null ||
      _dateTo != null ||
      !_newestFirst;

  int _doctorCount(List<ConsultationItem> items) {
    return items
        .map((ConsultationItem item) => item.doctorNameSnapshot.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .length;
  }

  int _diagnosisCount(List<ConsultationItem> items) {
    final Set<String> diagnoses = <String>{};

    for (final ConsultationItem item in items) {
      for (final DiagnosisEntry diagnosis in item.diagnoses) {
        final String value = diagnosis.description.trim();

        if (value.isNotEmpty) {
          diagnoses.add(value);
        }
      }
    }

    return diagnoses.length;
  }

  @override
  Widget build(BuildContext context) {
    final List<ConsultationItem> filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolución clínica'),
        actions: [
          if (_exportingPdf)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            PopupMenuButton<_PdfAction>(
              tooltip: 'Opciones del informe PDF',
              enabled: filteredItems.isNotEmpty,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onSelected: _runPdfAction,
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<_PdfAction>>[
                    PopupMenuItem<_PdfAction>(
                      value: _PdfAction.print,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.print_outlined),
                        title: Text('Imprimir o guardar'),
                      ),
                    ),
                    PopupMenuItem<_PdfAction>(
                      value: _PdfAction.save,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.save_alt_outlined),
                        title: Text('Guardar archivo PDF'),
                      ),
                    ),
                    PopupMenuItem<_PdfAction>(
                      value: _PdfAction.share,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.share_outlined),
                        title: Text('Compartir PDF'),
                      ),
                    ),
                  ],
            ),
          IconButton(
            tooltip: _newestFirst
                ? 'Mostrar más antiguas primero'
                : 'Mostrar más recientes primero',
            onPressed: () {
              setState(() {
                _newestFirst = !_newestFirst;
              });
            },
            icon: Icon(
              _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
          ),
          if (_hasActiveFilters)
            IconButton(
              tooltip: 'Limpiar filtros',
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const _TimelineEmptyState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Buscar en la historia clínica',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDoctor,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Médico',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ..._doctors.map(
                                  (String doctor) => DropdownMenuItem<String>(
                                    value: doctor,
                                    child: Text(
                                      doctor,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedDoctor = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedDiagnosis,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Diagnóstico',
                                prefixIcon: Icon(
                                  Icons.medical_information_outlined,
                                ),
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Todos'),
                                ),
                                ..._diagnoses.map(
                                  (String diagnosis) =>
                                      DropdownMenuItem<String>(
                                        value: diagnosis,
                                        child: Text(
                                          diagnosis,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedDiagnosis = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.small,
                          children: [
                            ChoiceChip(
                              label: const Text('Todo'),
                              selected: _quickPeriod == _QuickPeriod.all,
                              onSelected: (_) =>
                                  _applyQuickPeriod(_QuickPeriod.all),
                            ),
                            ChoiceChip(
                              label: const Text('30 días'),
                              selected: _quickPeriod == _QuickPeriod.last30Days,
                              onSelected: (_) =>
                                  _applyQuickPeriod(_QuickPeriod.last30Days),
                            ),
                            ChoiceChip(
                              label: const Text('90 días'),
                              selected: _quickPeriod == _QuickPeriod.last90Days,
                              onSelected: (_) =>
                                  _applyQuickPeriod(_QuickPeriod.last90Days),
                            ),
                            ChoiceChip(
                              label: const Text('1 año'),
                              selected: _quickPeriod == _QuickPeriod.lastYear,
                              onSelected: (_) =>
                                  _applyQuickPeriod(_QuickPeriod.lastYear),
                            ),
                            if (_quickPeriod == _QuickPeriod.custom)
                              const Chip(
                                avatar: Icon(Icons.tune_outlined, size: 18),
                                label: Text('Personalizado'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDateFrom,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(
                                _dateFrom == null
                                    ? 'Desde'
                                    : _formatDate(_dateFrom!),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDateTo,
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(
                                _dateTo == null
                                    ? 'Hasta'
                                    : _formatDate(_dateTo!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _SummaryPanel(
                        consultationCount: filteredItems.length,
                        doctorCount: _doctorCount(filteredItems),
                        diagnosisCount: _diagnosisCount(filteredItems),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: filteredItems.isEmpty
                              ? null
                              : _areAllVisibleExpanded(filteredItems)
                              ? _collapseAllVisible
                              : _expandAllVisible,
                          icon: Icon(
                            _areAllVisibleExpanded(filteredItems)
                                ? Icons.unfold_less
                                : Icons.unfold_more,
                          ),
                          label: Text(
                            _areAllVisibleExpanded(filteredItems)
                                ? 'Contraer todas'
                                : 'Expandir todas',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredItems.isEmpty
                      ? _NoResultsState(onClear: _clearFilters)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.large,
                            0,
                            AppSpacing.large,
                            AppSpacing.large,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ConsultationItem item = filteredItems[index];
                            final bool showMonthHeader =
                                index == 0 ||
                                !_isSameMonth(
                                  filteredItems[index - 1].consultationDateTime,
                                  item.consultationDateTime,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showMonthHeader)
                                  _MonthHeader(date: item.consultationDateTime),
                                _TimelineEntry(
                                  item: item,
                                  isFirst: index == 0,
                                  isLast: index == filteredItems.length - 1,
                                  isExpanded: _expandedItemIds.contains(
                                    item.id,
                                  ),
                                  onToggleExpanded: () =>
                                      _toggleExpanded(item.id),
                                  onEdit: () => _openEditor(item),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime date;

  const _MonthHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.small,
        bottom: AppSpacing.medium,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 20),
          const SizedBox(width: AppSpacing.small),
          Text(
            _monthAndYear(date),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: AppSpacing.medium),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  static String _monthAndYear(DateTime value) {
    const List<String> months = <String>[
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${months[value.month - 1]} ${value.year}';
  }
}

class _SummaryPanel extends StatelessWidget {
  final int consultationCount;
  final int doctorCount;
  final int diagnosisCount;

  const _SummaryPanel({
    required this.consultationCount,
    required this.doctorCount,
    required this.diagnosisCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            Expanded(
              child: _SummaryValue(
                icon: Icons.event_note_outlined,
                value: consultationCount,
                label: 'Consultas',
              ),
            ),
            Expanded(
              child: _SummaryValue(
                icon: Icons.person_outline,
                value: doctorCount,
                label: 'Médicos',
              ),
            ),
            Expanded(
              child: _SummaryValue(
                icon: Icons.medical_information_outlined,
                value: diagnosisCount,
                label: 'Diagnósticos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _SummaryValue({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: AppSpacing.small),
        Text(
          value.toString(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final ConsultationItem item;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;

  const _TimelineEntry({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final Color lineColor = Theme.of(context).colorScheme.outlineVariant;
    final Color markerColor = Theme.of(context).colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onToggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 18,
                              color: markerColor,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                _formatDateTime(item.consultationDateTime),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Editar consulta',
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                        if (item.doctorNameSnapshot.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            item.specialtySnapshot.trim().isEmpty
                                ? item.doctorNameSnapshot
                                : '${item.doctorNameSnapshot} • '
                                      '${item.specialtySnapshot}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                        if (!isExpanded && item.reason.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            item.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (isExpanded && item.reason.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          _ClinicalField(label: 'Motivo', value: item.reason),
                        ],
                        if (isExpanded && item.diagnoses.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          Wrap(
                            spacing: AppSpacing.small,
                            runSpacing: AppSpacing.small,
                            children: item.diagnoses
                                .map(
                                  (DiagnosisEntry diagnosis) => Chip(
                                    avatar: const Icon(
                                      Icons.medical_information_outlined,
                                      size: 16,
                                    ),
                                    label: Text(diagnosis.description),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (isExpanded && item.treatment.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          _ClinicalField(
                            label: 'Tratamiento',
                            value: item.treatment,
                          ),
                        ],
                        if (isExpanded &&
                            item.prescribedMedication.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          _ClinicalField(
                            label: 'Medicación',
                            value: item.prescribedMedication,
                          ),
                        ],
                        if (isExpanded &&
                            item.requestedStudies.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          _ClinicalField(
                            label: 'Estudios',
                            value: item.requestedStudies,
                          ),
                        ],
                        if (isExpanded && item.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.medium),
                          _ClinicalField(
                            label: 'Observaciones',
                            value: item.notes,
                          ),
                        ],
                        if (!isExpanded && item.diagnoses.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            item.diagnoses
                                .map(
                                  (DiagnosisEntry diagnosis) =>
                                      diagnosis.description,
                                )
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _ClinicalField extends StatelessWidget {
  final String label;
  final String value;

  const _ClinicalField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline_outlined, size: 64),
            SizedBox(height: AppSpacing.medium),
            Text(
              'Todavía no hay consultas para mostrar.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onClear;

  const _NoResultsState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 56),
            const SizedBox(height: AppSpacing.medium),
            const Text(
              'No hay consultas que coincidan con los filtros.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
