import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../diagnoses/models/diagnosis_entry.dart';
import '../../diagnoses/services/consultation_diagnosis_library_service.dart';
import '../../doctors/models/doctor_item.dart';
import '../../doctors/screens/doctor_screen.dart';
import '../../doctors/services/doctor_storage_service.dart';
import '../models/consultation_item.dart';
import '../services/consultation_storage_service.dart';
import 'diagnosis_picker_screen.dart';

String formatConsultationDateTime(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/${value.year} $hour:$minute';
}

class ConsultationEditScreen extends StatefulWidget {
  final ConsultationItem? item;

  const ConsultationEditScreen({super.key, this.item});

  @override
  State<ConsultationEditScreen> createState() => _ConsultationEditScreenState();
}

class _ConsultationEditScreenState extends State<ConsultationEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _reasonController;
  late final TextEditingController _treatmentController;
  late final TextEditingController _medicationController;
  late final TextEditingController _studiesController;
  late final TextEditingController _notesController;

  late DateTime _consultationDateTime;
  DateTime? _nextControlDate;
  List<DoctorItem> _doctors = <DoctorItem>[];
  String? _selectedDoctorId;
  List<DiagnosisEntry> _diagnoses = <DiagnosisEntry>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final ConsultationItem? item = widget.item;

    _reasonController = TextEditingController(text: item?.reason ?? '');
    _treatmentController = TextEditingController(text: item?.treatment ?? '');
    _medicationController = TextEditingController(
      text: item?.prescribedMedication ?? '',
    );
    _studiesController = TextEditingController(
      text: item?.requestedStudies ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _consultationDateTime = item?.consultationDateTime ?? DateTime.now();
    _nextControlDate = item?.nextControlDate;
    _doctors = DoctorStorageService.loadItems();
    _selectedDoctorId = item?.doctorId.isNotEmpty == true
        ? item!.doctorId
        : null;
    _diagnoses = List<DiagnosisEntry>.from(
      item?.diagnoses ?? const <DiagnosisEntry>[],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _treatmentController.dispose();
    _medicationController.dispose();
    _studiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectConsultationDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _consultationDateTime,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_consultationDateTime),
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    setState(() {
      _consultationDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _selectNextControl() async {
    final DateTime now = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _nextControlDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 20),
    );

    if (selected != null && mounted) {
      setState(() {
        _nextControlDate = selected;
      });
    }
  }

  Future<void> _addDoctor() async {
    final Set<String> previousIds = _doctors
        .map((DoctorItem doctor) => doctor.id)
        .toSet();

    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => const DoctorEditScreen(),
      ),
    );

    if (changed != true || !mounted) {
      return;
    }

    final List<DoctorItem> updatedDoctors = DoctorStorageService.loadItems();
    DoctorItem? newDoctor;

    for (final DoctorItem doctor in updatedDoctors) {
      if (!previousIds.contains(doctor.id)) {
        newDoctor = doctor;
        break;
      }
    }

    setState(() {
      _doctors = updatedDoctors;
      _selectedDoctorId = newDoctor?.id ?? _selectedDoctorId;
    });

    if (newDoctor != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${newDoctor.fullName} fue agregado y seleccionado.'),
          ),
        );
    }
  }

  Future<void> _addDiagnosis() async {
    final DiagnosisEntry? diagnosis = await Navigator.of(context)
        .push<DiagnosisEntry>(
          MaterialPageRoute<DiagnosisEntry>(
            builder: (BuildContext context) => const DiagnosisPickerScreen(),
          ),
        );

    if (diagnosis == null || !mounted) {
      return;
    }

    final String normalizedNew = ConsultationDiagnosisLibraryService.normalize(
      diagnosis.description,
    );

    final bool alreadyExists = _diagnoses.any(
      (DiagnosisEntry current) =>
          ConsultationDiagnosisLibraryService.normalize(current.description) ==
          normalizedNew,
    );

    if (!alreadyExists) {
      setState(() {
        _diagnoses.add(diagnosis);
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final DoctorItem? doctor = _selectedDoctorId == null
        ? null
        : _doctors.cast<DoctorItem?>().firstWhere(
            (DoctorItem? item) => item?.id == _selectedDoctorId,
            orElse: () => null,
          );

    final DateTime now = DateTime.now();
    final ConsultationItem? current = widget.item;

    final ConsultationItem item = ConsultationItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      consultationDateTime: _consultationDateTime,
      doctorId: doctor?.id ?? '',
      doctorNameSnapshot: doctor?.fullName ?? '',
      specialtySnapshot: doctor?.specialty ?? '',
      reason: _reasonController.text.trim(),
      diagnoses: _diagnoses,
      treatment: _treatmentController.text.trim(),
      prescribedMedication: _medicationController.text.trim(),
      requestedStudies: _studiesController.text.trim(),
      nextControlDate: _nextControlDate,
      notes: _notesController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await ConsultationStorageService.saveItem(item);
    await ConsultationDiagnosisLibraryService.registerDiagnoses(_diagnoses);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nueva consulta' : 'Editar consulta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectConsultationDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(formatConsultationDateTime(_consultationDateTime)),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDoctorId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Médico',
                      prefixIcon: Icon(AppIcons.doctors),
                    ),
                    items: _doctors.map((DoctorItem doctor) {
                      return DropdownMenuItem<String>(
                        value: doctor.id,
                        child: Text(
                          doctor.specialty.isEmpty
                              ? doctor.fullName
                              : '${doctor.fullName} • ${doctor.specialty}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedDoctorId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filledTonal(
                    tooltip: 'Agregar médico',
                    onPressed: _addDoctor,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _reasonController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Motivo de consulta',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.question_answer_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Diagnósticos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Agregar diagnóstico',
                          onPressed: _addDiagnosis,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (_diagnoses.isEmpty)
                      const Text('Sin diagnósticos registrados.')
                    else
                      ..._diagnoses.map(
                        (DiagnosisEntry diagnosis) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(diagnosis.description),
                          trailing: IconButton(
                            tooltip: 'Quitar',
                            onPressed: () {
                              setState(() {
                                _diagnoses.remove(diagnosis);
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _treatmentController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Tratamiento indicado',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.healing_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _medicationController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Medicación recetada',
                alignLabelWithHint: true,
                prefixIcon: Icon(AppIcons.medications),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _studiesController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Estudios solicitados',
                alignLabelWithHint: true,
                prefixIcon: Icon(AppIcons.studies),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectNextControl,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Próximo control',
                  prefixIcon: Icon(Icons.event_repeat_outlined),
                ),
                child: Text(
                  _nextControlDate == null
                      ? 'No especificado'
                      : _formatDate(_nextControlDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
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
              label: Text(_saving ? 'Guardando...' : 'Guardar consulta'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
