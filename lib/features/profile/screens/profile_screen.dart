import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/blood_type.dart';
import '../models/medical_profile.dart';
import '../services/medical_profile_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _documentNumberController;
  late final TextEditingController _healthInsuranceController;
  late final TextEditingController _membershipNumberController;
  late final TextEditingController _emergencyContactNameController;
  late final TextEditingController _emergencyContactPhoneController;
  late final TextEditingController _notesController;

  DateTime? _birthDate;
  BloodType _bloodType = BloodType.unknown;
  DateTime? _updatedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final MedicalProfile profile = MedicalProfileStorageService.loadProfile();

    _fullNameController = TextEditingController(text: profile.fullName);
    _documentNumberController = TextEditingController(
      text: profile.documentNumber,
    );
    _healthInsuranceController = TextEditingController(
      text: profile.healthInsurance,
    );
    _membershipNumberController = TextEditingController(
      text: profile.membershipNumber,
    );
    _emergencyContactNameController = TextEditingController(
      text: profile.emergencyContactName,
    );
    _emergencyContactPhoneController = TextEditingController(
      text: profile.emergencyContactPhone,
    );
    _notesController = TextEditingController(text: profile.notes);

    _birthDate = profile.birthDate;
    _bloodType = profile.bloodType;
    _updatedAt = profile.updatedAt;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _documentNumberController.dispose();
    _healthInsuranceController.dispose();
    _membershipNumberController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Seleccionar fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;
    });
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final MedicalProfile savedProfile =
          await MedicalProfileStorageService.saveProfile(
            MedicalProfile(
              fullName: _fullNameController.text.trim(),
              documentNumber: _documentNumberController.text.trim(),
              birthDate: _birthDate,
              bloodType: _bloodType,
              healthInsurance: _healthInsuranceController.text.trim(),
              membershipNumber: _membershipNumberController.text.trim(),
              emergencyContactName: _emergencyContactNameController.text.trim(),
              emergencyContactPhone: _emergencyContactPhoneController.text
                  .trim(),
              notes: _notesController.text.trim(),
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _updatedAt = savedProfile.updatedAt;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Perfil médico guardado correctamente.'),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No fue posible guardar el perfil: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteProfile() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar perfil'),
          content: const Text(
            'Se eliminarán todos los datos guardados en el perfil médico.',
          ),
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

    await MedicalProfileStorageService.deleteProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _fullNameController.clear();
      _documentNumberController.clear();
      _healthInsuranceController.clear();
      _membershipNumberController.clear();
      _emergencyContactNameController.clear();
      _emergencyContactPhoneController.clear();
      _notesController.clear();
      _birthDate = null;
      _bloodType = BloodType.unknown;
      _updatedAt = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Perfil médico eliminado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil médico'),
        actions: [
          IconButton(
            tooltip: 'Eliminar perfil',
            onPressed: _saving ? null : _deleteProfile,
            icon: const Icon(AppIcons.delete),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              const _ProfileIntroCard(),
              const SizedBox(height: AppSpacing.xLarge),
              _SectionCard(
                title: 'Datos personales',
                icon: AppIcons.profile,
                children: [
                  TextFormField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre y apellido',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _nameValidator,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextFormField(
                    controller: _documentNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: _documentValidator,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _BirthDateField(value: _birthDate, onTap: _selectBirthDate),
                  const SizedBox(height: AppSpacing.medium),
                  DropdownButtonFormField<BloodType>(
                    initialValue: _bloodType,
                    decoration: const InputDecoration(
                      labelText: 'Grupo sanguíneo',
                      prefixIcon: Icon(Icons.bloodtype_outlined),
                    ),
                    items: BloodType.values
                        .map(
                          (BloodType type) => DropdownMenuItem<BloodType>(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (BloodType? value) {
                      setState(() {
                        _bloodType = value ?? BloodType.unknown;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              _SectionCard(
                title: 'Cobertura médica',
                icon: Icons.health_and_safety_outlined,
                children: [
                  TextFormField(
                    controller: _healthInsuranceController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Obra social o prepaga',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextFormField(
                    controller: _membershipNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Número de afiliado',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              _SectionCard(
                title: 'Contacto de emergencia',
                icon: Icons.contact_emergency_outlined,
                children: [
                  TextFormField(
                    controller: _emergencyContactNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del contacto',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextFormField(
                    controller: _emergencyContactPhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: _phoneValidator,
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
                    minLines: 4,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Notas médicas generales',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                  ),
                ],
              ),
              if (_updatedAt != null) ...[
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Última actualización: ${_formatDateTime(_updatedAt!)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.xLarge),
              FilledButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.save),
                label: Text(_saving ? 'Guardando...' : 'Guardar perfil'),
              ),
              const SizedBox(height: AppSpacing.xLarge),
            ],
          ),
        ),
      ),
    );
  }

  static String? _nameValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa el nombre y apellido.';
    }
    if (text.length < 3) {
      return 'El nombre es demasiado corto.';
    }
    return null;
  }

  static String? _documentValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (text.length < 7 || text.length > 9) {
      return 'El DNI debe contener entre 7 y 9 números.';
    }
    return null;
  }

  static String? _phoneValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final String digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) {
      return 'El teléfono ingresado es demasiado corto.';
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final String hours = date.hour.toString().padLeft(2, '0');
    final String minutes = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hours:$minutes';
  }
}

class _ProfileIntroCard extends StatelessWidget {
  const _ProfileIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(AppIcons.profile),
            ),
            SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Text(
                'Registra los datos básicos que pueden ser importantes '
                'durante una consulta o una emergencia.',
              ),
            ),
          ],
        ),
      ),
    );
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

class _BirthDateField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;

  const _BirthDateField({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de nacimiento',
          prefixIcon: Icon(Icons.calendar_month_outlined),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value == null
              ? 'Seleccionar fecha'
              : _ProfileScreenState._formatDate(value!),
        ),
      ),
    );
  }
}
