import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/doctor_item.dart';
import '../services/doctor_storage_service.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  List<DoctorItem> _items = <DoctorItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = DoctorStorageService.loadItems();
    });
  }

  Future<void> _openEditor([DoctorItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DoctorEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _deleteItem(DoctorItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar profesional'),
          content: Text('Se eliminará a "${item.fullName}".'),
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

    await DoctorStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profesional eliminado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Médicos y centros de salud')),
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
                final DoctorItem item = _items[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.large),
                    leading: CircleAvatar(
                      backgroundColor: Color(item.colorValue),
                      foregroundColor: Colors.white,
                      child: const Icon(AppIcons.doctors),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.isPrimaryDoctor)
                          const Tooltip(
                            message: 'Médico de cabecera',
                            child: Icon(Icons.star, color: AppColors.warning),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.specialty.trim().isNotEmpty)
                            Text(item.specialty),
                          if (item.institution.trim().isNotEmpty)
                            Text(item.institution),
                          if (item.mobile.trim().isNotEmpty)
                            Text('Celular: ${item.mobile}'),
                          if (item.phone.trim().isNotEmpty)
                            Text('Teléfono: ${item.phone}'),
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
                        return const <PopupMenuEntry<String>>[
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

class DoctorEditScreen extends StatefulWidget {
  final DoctorItem? item;

  const DoctorEditScreen({super.key, this.item});

  @override
  State<DoctorEditScreen> createState() => _DoctorEditScreenState();
}

class _DoctorEditScreenState extends State<DoctorEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _licenseController;
  late final TextEditingController _phoneController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _institutionController;
  late final TextEditingController _officeController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _isPrimaryDoctor = false;
  int _colorValue = 0xFF1565C0;
  bool _saving = false;

  static const List<int> _availableColors = <int>[
    0xFF1565C0,
    0xFF2E7D32,
    0xFF6A1B9A,
    0xFFC62828,
    0xFFEF6C00,
    0xFF00695C,
  ];

  @override
  void initState() {
    super.initState();

    final DoctorItem? item = widget.item;

    _firstNameController = TextEditingController(text: item?.firstName ?? '');
    _lastNameController = TextEditingController(text: item?.lastName ?? '');
    _specialtyController = TextEditingController(text: item?.specialty ?? '');
    _licenseController = TextEditingController(text: item?.licenseNumber ?? '');
    _phoneController = TextEditingController(text: item?.phone ?? '');
    _mobileController = TextEditingController(text: item?.mobile ?? '');
    _emailController = TextEditingController(text: item?.email ?? '');
    _websiteController = TextEditingController(text: item?.website ?? '');
    _institutionController = TextEditingController(
      text: item?.institution ?? '',
    );
    _officeController = TextEditingController(text: item?.office ?? '');
    _addressController = TextEditingController(text: item?.address ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _isPrimaryDoctor = item?.isPrimaryDoctor ?? false;
    _colorValue = item?.colorValue ?? 0xFF1565C0;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _specialtyController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _institutionController.dispose();
    _officeController.dispose();
    _addressController.dispose();
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
    final DoctorItem? current = widget.item;

    final DoctorItem item = DoctorItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      specialty: _specialtyController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      phone: _phoneController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      institution: _institutionController.text.trim(),
      office: _officeController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      isPrimaryDoctor: _isPrimaryDoctor,
      colorValue: _colorValue,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await DoctorStorageService.saveItem(item);

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
          widget.item == null ? 'Nuevo profesional' : 'Editar profesional',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            _SectionCard(
              title: 'Datos profesionales',
              icon: AppIcons.doctors,
              children: [
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _specialtyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Médico de cabecera'),
                  subtitle: const Text('Solo puede haber uno por integrante.'),
                  value: _isPrimaryDoctor,
                  onChanged: (bool value) {
                    setState(() {
                      _isPrimaryDoctor = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionCard(
              title: 'Contacto',
              icon: Icons.contact_phone_outlined,
              children: [
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    prefixIcon: Icon(Icons.smartphone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _emailValidator,
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Sitio web',
                    prefixIcon: Icon(Icons.language_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionCard(
              title: 'Centro de salud',
              icon: Icons.local_hospital_outlined,
              children: [
                TextFormField(
                  controller: _institutionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Hospital, clínica o centro',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _officeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Consultorio',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionCard(
              title: 'Identificación visual',
              icon: Icons.palette_outlined,
              children: [
                Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.medium,
                  children: _availableColors.map((int colorValue) {
                    final bool selected = colorValue == _colorValue;

                    return InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        setState(() {
                          _colorValue = colorValue;
                        });
                      },
                      child: CircleAvatar(
                        radius: selected ? 25 : 22,
                        backgroundColor: Color(colorValue),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            _SectionCard(
              title: 'Observaciones',
              icon: Icons.notes_outlined,
              children: [
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
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
              label: Text(_saving ? 'Guardando...' : 'Guardar profesional'),
            ),
          ],
        ),
      ),
    );
  }

  static String? _requiredValidator(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  static String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.small),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            ...children,
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
            const Icon(AppIcons.doctors, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay médicos registrados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar médico'),
            ),
          ],
        ),
      ),
    );
  }
}
