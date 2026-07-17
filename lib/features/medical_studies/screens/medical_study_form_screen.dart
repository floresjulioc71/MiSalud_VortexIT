import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/medical_study.dart';
import '../services/medical_study_file_service.dart';
import '../services/medical_study_storage_service.dart';

class MedicalStudyFormScreen extends StatefulWidget {
  final MedicalStudy? item;

  const MedicalStudyFormScreen({super.key, this.item});

  @override
  State<MedicalStudyFormScreen> createState() => _MedicalStudyFormScreenState();
}

class _MedicalStudyFormScreenState extends State<MedicalStudyFormScreen> {
  static const Uuid _uuid = Uuid();
  static const List<String> _studyTypes = <String>[
    'Análisis de laboratorio',
    'Radiografía',
    'Ecografía',
    'Resonancia magnética',
    'Tomografía',
    'Electrocardiograma',
    'Ecocardiograma',
    'Endoscopía',
    'Colonoscopía',
    'Mamografía',
    'PAP',
    'Densitometría',
    'Audiometría',
    'Espirometría',
    'Otro',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _centerController;
  late final TextEditingController _professionalController;
  late final TextEditingController _resultController;
  late final TextEditingController _notesController;
  late String _type;
  late DateTime _studyDate;
  DateTime? _nextCheckDate;
  late MedicalStudyStatus _status;
  late List<MedicalStudyAttachment> _attachments;
  bool _saving = false;
  bool _addingFiles = false;

  @override
  void initState() {
    super.initState();
    final MedicalStudy? item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _centerController = TextEditingController(text: item?.medicalCenter ?? '');
    _professionalController = TextEditingController(
      text: item?.professional ?? '',
    );
    _resultController = TextEditingController(text: item?.result ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _type = item?.type.isNotEmpty == true ? item!.type : _studyTypes.first;
    _studyDate = item?.studyDate ?? DateTime.now();
    _nextCheckDate = item?.nextCheckDate;
    _status = item?.status ?? MedicalStudyStatus.pending;
    _attachments = List<MedicalStudyAttachment>.from(
      item?.attachments ?? <MedicalStudyAttachment>[],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _centerController.dispose();
    _professionalController.dispose();
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
    );
  }

  Future<void> _addFiles() async {
    if (_addingFiles) {
      return;
    }
    setState(() => _addingFiles = true);
    try {
      final List<MedicalStudyAttachment> files =
          await MedicalStudyFileService.pickAndCopyFiles();
      if (mounted && files.isNotEmpty) {
        setState(() => _attachments.addAll(files));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible adjuntar archivos: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingFiles = false);
      }
    }
  }

  Future<void> _removeAttachment(MedicalStudyAttachment attachment) async {
    setState(() => _attachments.remove(attachment));
    await MedicalStudyFileService.deletePhysicalFile(attachment);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final MedicalStudy item = MedicalStudy(
        id: widget.item?.id ?? _uuid.v4(),
        studyDate: _studyDate,
        type: _type,
        name: _nameController.text.trim(),
        medicalCenter: _centerController.text.trim(),
        professional: _professionalController.text.trim(),
        status: _status,
        result: _resultController.text.trim(),
        notes: _notesController.text.trim(),
        nextCheckDate: _nextCheckDate,
        attachments: List<MedicalStudyAttachment>.from(_attachments),
      );
      await MedicalStudyStorageService.upsert(item);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible guardar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nuevo estudio' : 'Editar estudio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de estudio',
                border: OutlineInputBorder(),
              ),
              items: _studyTypes
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() => _type = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre o descripción',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) =>
                  value == null || value.trim().isEmpty
                  ? 'Ingresá el nombre del estudio.'
                  : null,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Fecha del estudio',
              value: _studyDate,
              onTap: () async {
                final DateTime? date = await _pickDate(_studyDate);
                if (date != null) {
                  setState(() => _studyDate = date);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MedicalStudyStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: MedicalStudyStatus.values
                  .map(
                    (MedicalStudyStatus value) =>
                        DropdownMenuItem<MedicalStudyStatus>(
                          value: value,
                          child: Text(value.label),
                        ),
                  )
                  .toList(),
              onChanged: (MedicalStudyStatus? value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _centerController,
              decoration: const InputDecoration(
                labelText: 'Centro médico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _professionalController,
              decoration: const InputDecoration(
                labelText: 'Profesional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _resultController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Resultado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Próximo control (opcional)',
              value: _nextCheckDate,
              allowClear: true,
              onClear: () => setState(() => _nextCheckDate = null),
              onTap: () async {
                final DateTime? date = await _pickDate(
                  _nextCheckDate ?? DateTime.now(),
                );
                if (date != null) {
                  setState(() => _nextCheckDate = date);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Archivos adjuntos (${_attachments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _addingFiles ? null : _addFiles,
                  icon: _addingFiles
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: const Text('Adjuntar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_attachments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay archivos adjuntos.'),
                ),
              )
            else
              ..._attachments.map(
                (MedicalStudyAttachment attachment) => Card(
                  child: ListTile(
                    leading: Icon(
                      attachment.isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(attachment.name),
                    subtitle: Text(_fileSize(attachment.sizeBytes)),
                    trailing: IconButton(
                      tooltip: 'Quitar',
                      onPressed: () => _removeAttachment(attachment),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Guardar estudio'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static String _fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool allowClear;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.allowClear = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: allowClear && value != null
              ? IconButton(
                  tooltip: 'Limpiar',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                )
              : const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(value == null ? 'Sin fecha' : _date(value!)),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
