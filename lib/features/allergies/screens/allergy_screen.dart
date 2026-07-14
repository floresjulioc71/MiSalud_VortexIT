import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/allergy_item.dart';
import '../services/allergy_storage_service.dart';

class AllergyScreen extends StatefulWidget {
  const AllergyScreen({super.key});

  @override
  State<AllergyScreen> createState() => _AllergyScreenState();
}

class _AllergyScreenState extends State<AllergyScreen> {
  List<AllergyItem> _items = <AllergyItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = AllergyStorageService.loadItems();
    });
  }

  Future<void> _openEditor([AllergyItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => AllergyEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(AllergyItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar alergia'),
          content: Text('Se eliminará "${item.allergen}".'),
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

    await AllergyStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Alergia eliminada.')));
  }

  Color _severityColor(AllergySeverity severity) {
    switch (severity) {
      case AllergySeverity.mild:
        return AppColors.success;
      case AllergySeverity.moderate:
        return AppColors.warning;
      case AllergySeverity.severe:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alergias')),
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
                final AllergyItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: _severityColor(
                        item.severity,
                      ).withValues(alpha: 0.15),
                      child: Icon(
                        AppIcons.allergies,
                        color: _severityColor(item.severity),
                      ),
                    ),
                    title: Text(
                      item.allergen,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tipo: ${item.type.label}'),
                          Text('Gravedad: ${item.severity.label}'),
                          if (item.reaction.trim().isNotEmpty)
                            Text('Reacción: ${item.reaction}'),
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

class AllergyEditScreen extends StatefulWidget {
  final AllergyItem? item;

  const AllergyEditScreen({super.key, this.item});

  @override
  State<AllergyEditScreen> createState() => _AllergyEditScreenState();
}

class _AllergyEditScreenState extends State<AllergyEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _allergenController;
  late final TextEditingController _reactionController;
  late final TextEditingController _notesController;

  AllergyType _type = AllergyType.other;
  AllergySeverity _severity = AllergySeverity.mild;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final AllergyItem? item = widget.item;

    _allergenController = TextEditingController(text: item?.allergen ?? '');
    _reactionController = TextEditingController(text: item?.reaction ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _type = item?.type ?? AllergyType.other;
    _severity = item?.severity ?? AllergySeverity.mild;
  }

  @override
  void dispose() {
    _allergenController.dispose();
    _reactionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final DateTime now = DateTime.now();
    final AllergyItem? current = widget.item;

    final AllergyItem item = AllergyItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      allergen: _allergenController.text.trim(),
      type: _type,
      severity: _severity,
      reaction: _reactionController.text.trim(),
      notes: _notesController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await AllergyStorageService.saveItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nueva alergia' : 'Editar alergia'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _allergenController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alergia o alérgeno',
                prefixIcon: Icon(AppIcons.allergies),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa la alergia o el alérgeno.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<AllergyType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AllergyType.values
                  .map(
                    (AllergyType type) => DropdownMenuItem<AllergyType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (AllergyType? value) {
                setState(() {
                  _type = value ?? AllergyType.other;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<AllergySeverity>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Gravedad',
                prefixIcon: Icon(Icons.warning_amber_outlined),
              ),
              items: AllergySeverity.values
                  .map(
                    (AllergySeverity severity) =>
                        DropdownMenuItem<AllergySeverity>(
                          value: severity,
                          child: Text(severity.label),
                        ),
                  )
                  .toList(),
              onChanged: (AllergySeverity? value) {
                setState(() {
                  _severity = value ?? AllergySeverity.mild;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _reactionController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reacción',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.sick_outlined),
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
              label: Text(_saving ? 'Guardando...' : 'Guardar alergia'),
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
            const Icon(AppIcons.allergies, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay alergias registradas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar alergia'),
            ),
          ],
        ),
      ),
    );
  }
}
