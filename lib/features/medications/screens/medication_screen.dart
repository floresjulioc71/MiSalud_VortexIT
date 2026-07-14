import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/medication_item.dart';
import '../services/medication_storage_service.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  List<MedicationItem> _items = <MedicationItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = MedicationStorageService.loadItems();
    });
  }

  Future<void> _openEditor([MedicationItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => MedicationEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(MedicationItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar medicamento'),
          content: Text('Se eliminará "${item.name}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await MedicationStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Medicamento eliminado.')));
  }

  Color _statusColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.active:
        return AppColors.success;
      case MedicationStatus.paused:
        return AppColors.warning;
      case MedicationStatus.completed:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(AppIcons.add),
        label: const Text('Agregar'),
      ),
      body: _items.isEmpty
          ? _EmptyState(onAdd: () => _openEditor())
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.large),
              itemCount: _items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.medium),
              itemBuilder: (BuildContext context, int index) {
                final MedicationItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(
                        item.status,
                      ).withValues(alpha: 0.15),
                      child: Icon(
                        AppIcons.medications,
                        color: _statusColor(item.status),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.activeIngredient.trim().isNotEmpty)
                            Text('Principio activo: ${item.activeIngredient}'),
                          if (item.dose.trim().isNotEmpty)
                            Text('Dosis: ${item.dose}'),
                          if (item.frequency.trim().isNotEmpty)
                            Text('Frecuencia: ${item.frequency}'),
                          Text('Estado: ${item.status.label}'),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'edit') {
                          _openEditor(item);
                        } else if (value == 'delete') {
                          _deleteItem(item);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ];
                      },
                    ),
                    onTap: () => _openEditor(item),
                  ),
                );
              },
            ),
    );
  }
}

class MedicationEditScreen extends StatefulWidget {
  final MedicationItem? item;

  const MedicationEditScreen({super.key, this.item});

  @override
  State<MedicationEditScreen> createState() => _MedicationEditScreenState();
}

class _MedicationEditScreenState extends State<MedicationEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _activeIngredientController;
  late final TextEditingController _doseController;
  late final TextEditingController _frequencyController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _prescribedByController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _notesController;

  MedicationRoute _route = MedicationRoute.oral;
  MedicationStatus _status = MedicationStatus.active;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final MedicationItem? item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _activeIngredientController = TextEditingController(
      text: item?.activeIngredient ?? '',
    );
    _doseController = TextEditingController(text: item?.dose ?? '');
    _frequencyController = TextEditingController(text: item?.frequency ?? '');
    _scheduleController = TextEditingController(text: item?.schedule ?? '');
    _prescribedByController = TextEditingController(
      text: item?.prescribedBy ?? '',
    );
    _instructionsController = TextEditingController(
      text: item?.instructions ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _route = item?.route ?? MedicationRoute.oral;
    _status = item?.status ?? MedicationStatus.active;
    _startDate = item?.startDate;
    _endDate = item?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activeIngredientController.dispose();
    _doseController.dispose();
    _frequencyController.dispose();
    _scheduleController.dispose();
    _prescribedByController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 20),
      helpText: 'Fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;
      if (_endDate != null && _endDate!.isBefore(selected)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = _startDate ?? DateTime(1900);
    final DateTime initialDate = _endDate ?? _startDate ?? now;

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 20),
      helpText: 'Fecha de finalización',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final DateTime now = DateTime.now();
    final MedicationItem? current = widget.item;

    final MedicationItem item = MedicationItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      activeIngredient: _activeIngredientController.text.trim(),
      dose: _doseController.text.trim(),
      frequency: _frequencyController.text.trim(),
      schedule: _scheduleController.text.trim(),
      route: _route,
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      prescribedBy: _prescribedByController.text.trim(),
      instructions: _instructionsController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await MedicationStorageService.saveItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Nuevo medicamento' : 'Editar medicamento',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
                prefixIcon: Icon(AppIcons.medications),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el nombre del medicamento.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _activeIngredientController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Principio activo',
                prefixIcon: Icon(Icons.science_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dosis',
                hintText: 'Ej.: 500 mg',
                prefixIcon: Icon(Icons.straighten_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _frequencyController,
              decoration: const InputDecoration(
                labelText: 'Frecuencia',
                hintText: 'Ej.: Cada 8 horas',
                prefixIcon: Icon(Icons.repeat_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _scheduleController,
              decoration: const InputDecoration(
                labelText: 'Horario',
                hintText: 'Ej.: 08:00, 16:00 y 00:00',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<MedicationRoute>(
              initialValue: _route,
              decoration: const InputDecoration(
                labelText: 'Vía de administración',
                prefixIcon: Icon(Icons.route_outlined),
              ),
              items: MedicationRoute.values
                  .map(
                    (MedicationRoute route) =>
                        DropdownMenuItem<MedicationRoute>(
                          value: route,
                          child: Text(route.label),
                        ),
                  )
                  .toList(),
              onChanged: (MedicationRoute? value) {
                setState(() {
                  _route = value ?? MedicationRoute.other;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            _DateField(
              label: 'Fecha de inicio',
              value: _startDate,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: AppSpacing.medium),
            _DateField(
              label: 'Fecha de finalización',
              value: _endDate,
              onTap: _selectEndDate,
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<MedicationStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: MedicationStatus.values
                  .map(
                    (MedicationStatus status) =>
                        DropdownMenuItem<MedicationStatus>(
                          value: status,
                          child: Text(status.label),
                        ),
                  )
                  .toList(),
              onChanged: (MedicationStatus? value) {
                setState(() {
                  _status = value ?? MedicationStatus.active;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _prescribedByController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Indicado por',
                prefixIcon: Icon(AppIcons.doctors),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _instructionsController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Indicaciones',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notas',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
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
              label: Text(_saving ? 'Guardando...' : 'Guardar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
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
        ),
        child: Text(value == null ? 'No especificada' : _formatDate(value!)),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.medications,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay medicamentos registrados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
