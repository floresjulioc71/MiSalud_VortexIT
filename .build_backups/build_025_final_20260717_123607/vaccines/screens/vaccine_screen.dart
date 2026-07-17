import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/vaccine_item.dart';
import '../services/vaccine_file_service.dart';
import '../services/vaccine_storage_service.dart';

class VaccineScreen extends StatefulWidget {
  const VaccineScreen({super.key});

  @override
  State<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends State<VaccineScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<VaccineItem> _items = <VaccineItem>[];
  VaccineStatus? _statusFilter;
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
    await VaccineStorageService.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _items = VaccineStorageService.loadItems();
      _loading = false;
    });
  }

  List<VaccineItem> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();
    final DateTime now = DateTime.now();

    return _items.where((VaccineItem item) {
      if (_statusFilter != null && item.statusAt(now) != _statusFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = <String>[
        item.name,
        item.disease,
        item.dose,
        item.laboratory,
        item.lotNumber,
        item.applicationPlace,
        item.professional,
        item.notes,
        item.statusAt(now).label,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _openEditor([VaccineItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => VaccineEditScreen(item: item),
      ),
    );

    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openDetails(VaccineItem item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => VaccineDetailsScreen(item: item),
      ),
    );
  }

  Future<void> _deleteItem(VaccineItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar vacuna'),
        content: Text('Se eliminará "${item.name}".'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    for (final VaccineAttachment attachment in item.attachments) {
      await VaccineFileService.deleteAttachment(attachment);
    }

    await VaccineStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    await _reload();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Vacuna eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    final List<VaccineItem> visible = _filteredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(AppIcons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.large,
                    AppSpacing.medium,
                    AppSpacing.large,
                    AppSpacing.small,
                  ),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Buscar vacuna, enfermedad, lote o centro',
                    leading: const Icon(Icons.search),
                    trailing: _searchController.text.isEmpty
                        ? null
                        : <Widget>[
                            IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Limpiar',
                            ),
                          ],
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _statusFilter == null,
                        onSelected: (_) => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      ...VaccineStatus.values.map(
                        (VaccineStatus status) => Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.small,
                          ),
                          child: ChoiceChip(
                            label: Text(status.label),
                            selected: _statusFilter == status,
                            onSelected: (_) =>
                                setState(() => _statusFilter = status),
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
                            setState(() => _statusFilter = null);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.large,
                            AppSpacing.small,
                            AppSpacing.large,
                            96,
                          ),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.medium),
                          itemBuilder: (BuildContext context, int index) {
                            final VaccineItem item = visible[index];
                            final VaccineStatus status = item.statusAt(
                              DateTime.now(),
                            );

                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(
                                  AppSpacing.large,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: const Icon(AppIcons.vaccines),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.small,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      if (item.disease.isNotEmpty)
                                        Text(item.disease),
                                      if (item.applicationDate != null)
                                        Text(
                                          'Aplicación: '
                                          '${_formatDate(item.applicationDate!)}',
                                        ),
                                      Text(
                                        'Dosis ${item.doseNumber}/'
                                        '${item.totalDoses}',
                                      ),
                                      if (item.nextDoseDate != null)
                                        Text(
                                          'Próxima dosis: '
                                          '${_formatDate(item.nextDoseDate!)}',
                                        ),
                                      const SizedBox(height: AppSpacing.small),
                                      Wrap(
                                        spacing: AppSpacing.small,
                                        runSpacing: AppSpacing.small,
                                        children: <Widget>[
                                          Chip(
                                            label: Text(status.label),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          if (item.attachments.isNotEmpty)
                                            Chip(
                                              avatar: const Icon(
                                                Icons.attach_file,
                                                size: 16,
                                              ),
                                              label: Text(
                                                '${item.attachments.length}',
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (String value) {
                                    if (value == 'view') {
                                      _openDetails(item);
                                    } else if (value == 'edit') {
                                      _openEditor(item);
                                    } else if (value == 'delete') {
                                      _deleteItem(item);
                                    }
                                  },
                                  itemBuilder: (_) =>
                                      const <PopupMenuEntry<String>>[
                                        PopupMenuItem(
                                          value: 'view',
                                          child: Text('Ver'),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Editar'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Eliminar'),
                                        ),
                                      ],
                                ),
                                onTap: () => _openDetails(item),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class VaccineEditScreen extends StatefulWidget {
  final VaccineItem? item;

  const VaccineEditScreen({super.key, this.item});

  @override
  State<VaccineEditScreen> createState() => _VaccineEditScreenState();
}

class _VaccineEditScreenState extends State<VaccineEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _diseaseController;
  late final TextEditingController _doseController;
  late final TextEditingController _doseNumberController;
  late final TextEditingController _totalDosesController;
  late final TextEditingController _laboratoryController;
  late final TextEditingController _lotNumberController;
  late final TextEditingController _applicationPlaceController;
  late final TextEditingController _professionalController;
  late final TextEditingController _notesController;

  DateTime? _applicationDate;
  DateTime? _nextDoseDate;
  late List<VaccineAttachment> _attachments;

  bool _saving = false;
  bool _addingFiles = false;

  @override
  void initState() {
    super.initState();

    final VaccineItem? item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _diseaseController = TextEditingController(text: item?.disease ?? '');
    _doseController = TextEditingController(text: item?.dose ?? '');
    _doseNumberController = TextEditingController(
      text: (item?.doseNumber ?? 1).toString(),
    );
    _totalDosesController = TextEditingController(
      text: (item?.totalDoses ?? 1).toString(),
    );
    _laboratoryController = TextEditingController(text: item?.laboratory ?? '');
    _lotNumberController = TextEditingController(text: item?.lotNumber ?? '');
    _applicationPlaceController = TextEditingController(
      text: item?.applicationPlace ?? '',
    );
    _professionalController = TextEditingController(
      text: item?.professional ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _applicationDate = item?.applicationDate;
    _nextDoseDate = item?.nextDoseDate;
    _attachments = List<VaccineAttachment>.from(
      item?.attachments ?? const <VaccineAttachment>[],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diseaseController.dispose();
    _doseController.dispose();
    _doseNumberController.dispose();
    _totalDosesController.dispose();
    _laboratoryController.dispose();
    _lotNumberController.dispose();
    _applicationPlaceController.dispose();
    _professionalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectApplicationDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _applicationDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de aplicación',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _applicationDate = selected;

      if (_nextDoseDate != null && _nextDoseDate!.isBefore(selected)) {
        _nextDoseDate = null;
      }
    });
  }

  Future<void> _selectNextDoseDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = _applicationDate ?? now;
    final DateTime initialDate = _nextDoseDate ?? firstDate;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
      helpText: 'Próxima dosis',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() => _nextDoseDate = selected);
  }

  Future<void> _addFiles() async {
    if (_addingFiles) {
      return;
    }

    setState(() => _addingFiles = true);

    try {
      final List<VaccineAttachment> selected =
          await VaccineFileService.pickFiles();

      if (mounted && selected.isNotEmpty) {
        setState(() => _attachments.addAll(selected));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible adjuntar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingFiles = false);
      }
    }
  }

  Future<void> _removeAttachment(VaccineAttachment attachment) async {
    setState(() => _attachments.remove(attachment));
    await VaccineFileService.deleteAttachment(attachment);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final VaccineItem? current = widget.item;

    final VaccineItem item = VaccineItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      disease: _diseaseController.text.trim(),
      dose: _doseController.text.trim(),
      doseNumber: int.parse(_doseNumberController.text.trim()),
      totalDoses: int.parse(_totalDosesController.text.trim()),
      applicationDate: _applicationDate,
      laboratory: _laboratoryController.text.trim(),
      lotNumber: _lotNumberController.text.trim(),
      applicationPlace: _applicationPlaceController.text.trim(),
      professional: _professionalController.text.trim(),
      nextDoseDate: _nextDoseDate,
      notes: _notesController.text.trim(),
      attachments: List<VaccineAttachment>.from(_attachments),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await VaccineStorageService.saveItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nueva vacuna' : 'Editar vacuna'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vacuna',
                prefixIcon: Icon(AppIcons.vaccines),
              ),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _diseaseController,
              decoration: const InputDecoration(
                labelText: 'Enfermedad que previene',
                prefixIcon: Icon(Icons.health_and_safety_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Descripción de dosis',
                hintText: 'Ej.: Primera, segunda o refuerzo',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _doseNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'N.º de dosis',
                    ),
                    validator: _positiveInteger,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: TextFormField(
                    controller: _totalDosesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total esquema',
                    ),
                    validator: _positiveInteger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            _DateField(
              label: 'Fecha de aplicación',
              value: _applicationDate,
              onTap: _selectApplicationDate,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _laboratoryController,
              decoration: const InputDecoration(
                labelText: 'Laboratorio',
                prefixIcon: Icon(Icons.science_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _lotNumberController,
              decoration: const InputDecoration(
                labelText: 'Número de lote',
                prefixIcon: Icon(Icons.qr_code_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _applicationPlaceController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Lugar de aplicación',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _professionalController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Profesional',
                prefixIcon: Icon(AppIcons.doctors),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _DateField(
              label: 'Próxima dosis',
              value: _nextDoseDate,
              onTap: _selectNextDoseDate,
              onClear: _nextDoseDate == null
                  ? null
                  : () => setState(() => _nextDoseDate = null),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notas',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Comprobantes (${_attachments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _addingFiles ? null : _addFiles,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Adjuntar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            if (_attachments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: Text('No hay comprobantes adjuntos.'),
                ),
              )
            else
              ..._attachments.map(
                (VaccineAttachment attachment) => Card(
                  child: ListTile(
                    leading: Icon(
                      attachment.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(attachment.name),
                    trailing: IconButton(
                      tooltip: 'Quitar',
                      onPressed: () => _removeAttachment(attachment),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xLarge),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar vacuna'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Ingresa el nombre de la vacuna.';
    }
    return null;
  }

  String? _positiveInteger(String? value) {
    final int? parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) {
      return 'Número inválido.';
    }
    return null;
  }
}

class VaccineDetailsScreen extends StatelessWidget {
  final VaccineItem item;

  const VaccineDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final VaccineStatus status = item.statusAt(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                children: <Widget>[
                  _detail('Estado', status.label),
                  if (item.disease.isNotEmpty)
                    _detail('Previene', item.disease),
                  _detail('Dosis', '${item.doseNumber} de ${item.totalDoses}'),
                  if (item.dose.isNotEmpty) _detail('Descripción', item.dose),
                  if (item.applicationDate != null)
                    _detail(
                      'Aplicación',
                      _VaccineScreenState._formatDate(item.applicationDate!),
                    ),
                  if (item.laboratory.isNotEmpty)
                    _detail('Laboratorio', item.laboratory),
                  if (item.lotNumber.isNotEmpty)
                    _detail('Lote', item.lotNumber),
                  if (item.applicationPlace.isNotEmpty)
                    _detail('Lugar', item.applicationPlace),
                  if (item.professional.isNotEmpty)
                    _detail('Profesional', item.professional),
                  if (item.nextDoseDate != null)
                    _detail(
                      'Próxima dosis',
                      _VaccineScreenState._formatDate(item.nextDoseDate!),
                    ),
                  if (item.notes.isNotEmpty) _detail('Notas', item.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Text('Comprobantes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.small),
          if (item.attachments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.large),
                child: Text('No hay comprobantes adjuntos.'),
              ),
            )
          else
            ...item.attachments.map(
              (VaccineAttachment attachment) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (attachment.isImage &&
                        File(attachment.path).existsSync())
                      Image.file(
                        File(attachment.path),
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ListTile(
                      leading: Icon(
                        attachment.isPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                      ),
                      title: Text(attachment.name),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () =>
                          VaccineFileService.openAttachment(attachment),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        ),
        child: Text(
          value == null
              ? 'No especificada'
              : _VaccineScreenState._formatDate(value!),
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(AppIcons.vaccines, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              filtered
                  ? 'No hay vacunas que coincidan con los filtros.'
                  : 'Todavía no hay vacunas registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            if (filtered)
              OutlinedButton(
                onPressed: onClear,
                child: const Text('Limpiar filtros'),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(AppIcons.add),
                label: const Text('Agregar vacuna'),
              ),
          ],
        ),
      ),
    );
  }
}
