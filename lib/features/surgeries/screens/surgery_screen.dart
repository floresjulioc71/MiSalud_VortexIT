import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/surgery_item.dart';
import '../services/surgery_storage_service.dart';

class SurgeryScreen extends StatefulWidget {
  const SurgeryScreen({super.key});

  @override
  State<SurgeryScreen> createState() => _SurgeryScreenState();
}

class _SurgeryScreenState extends State<SurgeryScreen> {
  List<SurgeryItem> _items = <SurgeryItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = SurgeryStorageService.loadItems();
    });
  }

  Future<void> _openEditor([SurgeryItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => SurgeryEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(SurgeryItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar cirugía'),
          content: Text('Se eliminará "${item.procedure}".'),
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

    await SurgeryStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cirugía eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cirugías')),
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
                final SurgeryItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(AppIcons.surgeries),
                    ),
                    title: Text(
                      item.procedure,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.surgeryDate != null)
                            Text('Fecha: ${_formatDate(item.surgeryDate!)}'),
                          if (item.hospital.trim().isNotEmpty)
                            Text('Institución: ${item.hospital}'),
                          if (item.surgeon.trim().isNotEmpty)
                            Text('Profesional: ${item.surgeon}'),
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

class SurgeryEditScreen extends StatefulWidget {
  final SurgeryItem? item;

  const SurgeryEditScreen({super.key, this.item});

  @override
  State<SurgeryEditScreen> createState() => _SurgeryEditScreenState();
}

class _SurgeryEditScreenState extends State<SurgeryEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _procedureController;
  late final TextEditingController _hospitalController;
  late final TextEditingController _surgeonController;
  late final TextEditingController _reasonController;
  late final TextEditingController _complicationsController;
  late final TextEditingController _notesController;

  DateTime? _surgeryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final SurgeryItem? item = widget.item;

    _procedureController = TextEditingController(text: item?.procedure ?? '');
    _hospitalController = TextEditingController(text: item?.hospital ?? '');
    _surgeonController = TextEditingController(text: item?.surgeon ?? '');
    _reasonController = TextEditingController(text: item?.reason ?? '');
    _complicationsController = TextEditingController(
      text: item?.complications ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _surgeryDate = item?.surgeryDate;
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _hospitalController.dispose();
    _surgeonController.dispose();
    _reasonController.dispose();
    _complicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _surgeryDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de cirugía',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _surgeryDate = selected;
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
    final SurgeryItem? current = widget.item;

    final SurgeryItem item = SurgeryItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      procedure: _procedureController.text.trim(),
      surgeryDate: _surgeryDate,
      hospital: _hospitalController.text.trim(),
      surgeon: _surgeonController.text.trim(),
      reason: _reasonController.text.trim(),
      complications: _complicationsController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await SurgeryStorageService.saveItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nueva cirugía' : 'Editar cirugía'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _procedureController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Procedimiento o cirugía',
                prefixIcon: Icon(AppIcons.surgeries),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el procedimiento realizado.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de cirugía',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _surgeryDate == null
                      ? 'No especificada'
                      : _SurgeryScreenState._formatDate(_surgeryDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _hospitalController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Hospital o institución',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _surgeonController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Cirujano o profesional',
                prefixIcon: Icon(AppIcons.doctors),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _reasonController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _complicationsController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Complicaciones',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.warning_amber_outlined),
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
              label: Text(_saving ? 'Guardando...' : 'Guardar cirugía'),
            ),
          ],
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
            const Icon(AppIcons.surgeries, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay cirugías registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar cirugía'),
            ),
          ],
        ),
      ),
    );
  }
}
