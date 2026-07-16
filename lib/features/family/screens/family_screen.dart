import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/family_member.dart';
import '../services/family_storage_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<FamilyMember> _members = <FamilyMember>[];
  String _activeId = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _members = FamilyStorageService.loadMembers();
      _activeId = FamilyStorageService.activeMemberId;
    });
  }

  Future<void> _openEditor([FamilyMember? member]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FamilyMemberEditScreen(member: member),
      ),
    );
    if (changed == true) {
      _reload();
    }
  }

  Future<void> _select(FamilyMember member) async {
    await FamilyStorageService.setActiveMember(member.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${member.name} es la persona activa.')),
    );
  }

  Future<void> _delete(FamilyMember member) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar integrante'),
        content: Text('Se eliminará a "${member.name}" del grupo familiar.'),
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
      ),
    );

    if (confirmed != true) return;

    try {
      await FamilyStorageService.deleteMember(member.id);
      if (!mounted) return;
      _reload();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canAdd = _members.length < FamilyStorageService.maximumMembers;

    return Scaffold(
      appBar: AppBar(title: const Text('Grupo familiar')),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.large),
              child: Text(
                'Administra hasta 4 personas. Cada integrante mantiene '
                'sus datos médicos separados.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            '${_members.length}/4 integrantes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.medium),
          ..._members.map(
            (FamilyMember member) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.large),
                leading: CircleAvatar(
                  backgroundColor: member.id == _activeId
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: member.id == _activeId
                      ? Colors.white
                      : AppColors.primary,
                  child: const Icon(Icons.person_outline),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  member.relationship.isEmpty
                      ? 'Sin parentesco'
                      : member.relationship,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'select') _select(member);
                    if (value == 'edit') _openEditor(member);
                    if (value == 'delete') _delete(member);
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    if (member.id != _activeId)
                      const PopupMenuItem(
                        value: 'select',
                        child: Text('Seleccionar'),
                      ),
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
                onTap: () => _select(member),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyMemberEditScreen extends StatefulWidget {
  final FamilyMember? member;

  const FamilyMemberEditScreen({super.key, this.member});

  @override
  State<FamilyMemberEditScreen> createState() => _FamilyMemberEditScreenState();
}

class _FamilyMemberEditScreenState extends State<FamilyMemberEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _relationshipController;
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _relationshipController = TextEditingController(
      text: widget.member?.relationship ?? '',
    );
    _birthDate = widget.member?.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? value = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (value != null && mounted) {
      setState(() => _birthDate = value);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final FamilyMember? current = widget.member;
    final FamilyMember member = FamilyMember(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      relationship: _relationshipController.text.trim(),
      birthDate: _birthDate,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await FamilyStorageService.saveMember(member);
      if (current == null) {
        await FamilyStorageService.setActiveMember(member.id);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.member == null ? 'Nuevo integrante' : 'Editar integrante',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellido',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (String? value) =>
                  (value?.trim().length ?? 0) < 3 ? 'Ingresa el nombre.' : null,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Parentesco',
                hintText: 'Titular, pareja, hijo/a',
                prefixIcon: Icon(Icons.family_restroom_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? 'No especificada'
                      : _formatDate(_birthDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(AppIcons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar integrante'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
