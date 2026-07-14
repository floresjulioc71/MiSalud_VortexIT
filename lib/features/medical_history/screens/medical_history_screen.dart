import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/medical_history_item.dart';
import '../services/medical_history_storage_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  List<MedicalHistoryItem> _items = <MedicalHistoryItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = MedicalHistoryStorageService.loadItems();
    });
  }

  Future<void> _openEditor([MedicalHistoryItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => MedicalHistoryEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(MedicalHistoryItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar antecedente'),
          content: Text('Se eliminará "${item.title}".'),
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

    await MedicalHistoryStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Antecedente eliminado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antecedentes médicos')),
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
                final MedicalHistoryItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(AppIcons.medicalHistory),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.description.trim().isNotEmpty)
                            Text(item.description),
                          const SizedBox(height: AppSpacing.small),
                          Text('Estado: ${item.status.label}'),
                          if (item.diagnosisDate != null)
                            Text(
                              'Diagnóstico: ${_formatDate(item.diagnosisDate!)}',
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

class MedicalHistoryEditScreen extends StatefulWidget {
  final MedicalHistoryItem? item;

  const MedicalHistoryEditScreen({super.key, this.item});

  @override
  State<MedicalHistoryEditScreen> createState() =>
      _MedicalHistoryEditScreenState();
}

class _MedicalHistoryEditScreenState extends State<MedicalHistoryEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  DateTime? _diagnosisDate;
  MedicalHistoryStatus _status = MedicalHistoryStatus.active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final MedicalHistoryItem? item = widget.item;

    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _diagnosisDate = item?.diagnosisDate;
    _status = item?.status ?? MedicalHistoryStatus.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _diagnosisDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de diagnóstico',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _diagnosisDate = selected;
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
    final MedicalHistoryItem? current = widget.item;

    final MedicalHistoryItem item = MedicalHistoryItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      diagnosisDate: _diagnosisDate,
      status: _status,
      notes: _notesController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await MedicalHistoryStorageService.saveItem(item);

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
          widget.item == null ? 'Nuevo antecedente' : 'Editar antecedente',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Antecedente o diagnóstico',
                prefixIcon: Icon(AppIcons.medicalHistory),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el antecedente médico.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de diagnóstico',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _diagnosisDate == null
                      ? 'No especificada'
                      : _MedicalHistoryScreenState._formatDate(_diagnosisDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<MedicalHistoryStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: MedicalHistoryStatus.values
                  .map(
                    (MedicalHistoryStatus status) =>
                        DropdownMenuItem<MedicalHistoryStatus>(
                          value: status,
                          child: Text(status.label),
                        ),
                  )
                  .toList(),
              onChanged: (MedicalHistoryStatus? value) {
                setState(() {
                  _status = value ?? MedicalHistoryStatus.active;
                });
              },
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
              label: Text(_saving ? 'Guardando...' : 'Guardar antecedente'),
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
            const Icon(
              AppIcons.medicalHistory,
              size: 72,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay antecedentes registrados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar antecedente'),
            ),
          ],
        ),
      ),
    );
  }
}
