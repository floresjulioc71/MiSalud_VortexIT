import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/vaccine_item.dart';
import '../services/vaccine_storage_service.dart';

class VaccineScreen extends StatefulWidget {
  const VaccineScreen({super.key});

  @override
  State<VaccineScreen> createState() => _VaccineScreenState();
}

class _VaccineScreenState extends State<VaccineScreen> {
  List<VaccineItem> _items = <VaccineItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = VaccineStorageService.loadItems();
    });
  }

  Future<void> _openEditor([VaccineItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => VaccineEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(VaccineItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar vacuna'),
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

    await VaccineStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Vacuna eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas')),
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
                final VaccineItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(AppIcons.vaccines),
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
                          if (item.dose.trim().isNotEmpty)
                            Text('Dosis: ${item.dose}'),
                          if (item.applicationDate != null)
                            Text(
                              'Aplicación: ${_formatDate(item.applicationDate!)}',
                            ),
                          if (item.nextDoseDate != null)
                            Text(
                              'Próxima dosis: ${_formatDate(item.nextDoseDate!)}',
                            ),
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
  late final TextEditingController _doseController;
  late final TextEditingController _lotNumberController;
  late final TextEditingController _applicationPlaceController;
  late final TextEditingController _professionalController;
  late final TextEditingController _notesController;

  DateTime? _applicationDate;
  DateTime? _nextDoseDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final VaccineItem? item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _doseController = TextEditingController(text: item?.dose ?? '');
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
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
    final DateTime initialDate = _nextDoseDate ?? _applicationDate ?? now;

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

    setState(() {
      _nextDoseDate = selected;
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
    final VaccineItem? current = widget.item;

    final VaccineItem item = VaccineItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      dose: _doseController.text.trim(),
      applicationDate: _applicationDate,
      lotNumber: _lotNumberController.text.trim(),
      applicationPlace: _applicationPlaceController.text.trim(),
      professional: _professionalController.text.trim(),
      nextDoseDate: _nextDoseDate,
      notes: _notesController.text.trim(),
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
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Vacuna',
                prefixIcon: Icon(AppIcons.vaccines),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el nombre de la vacuna.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: 'Dosis',
                hintText: 'Ej.: Primera, segunda o refuerzo',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            _DateField(
              label: 'Fecha de aplicación',
              value: _applicationDate,
              onTap: _selectApplicationDate,
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
              label: Text(_saving ? 'Guardando...' : 'Guardar vacuna'),
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
            const Icon(AppIcons.vaccines, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay vacunas registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
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
