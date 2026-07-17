import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/vaccine_record.dart';
import '../services/vaccine_file_service.dart';
import '../services/vaccine_storage_service.dart';

class VaccineFormScreen extends StatefulWidget {
  final VaccineRecord? item;

  const VaccineFormScreen({super.key, this.item});

  @override
  State<VaccineFormScreen> createState() => _VaccineFormScreenState();
}

class _VaccineFormScreenState extends State<VaccineFormScreen> {
  static const Uuid _uuid = Uuid();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _diseaseController;
  late final TextEditingController _doseController;
  late final TextEditingController _totalDosesController;
  late final TextEditingController _laboratoryController;
  late final TextEditingController _lotController;
  late final TextEditingController _centerController;
  late final TextEditingController _professionalController;
  late final TextEditingController _notesController;
  late DateTime _applicationDate;
  DateTime? _nextDoseDate;
  late List<VaccineAttachment> _attachments;
  bool _saving = false;
  bool _addingFiles = false;

  @override
  void initState() {
    super.initState();
    final VaccineRecord? item = widget.item;
    _nameController = TextEditingController(text: item?.vaccineName ?? '');
    _diseaseController = TextEditingController(
      text: item?.preventsDisease ?? '',
    );
    _doseController = TextEditingController(
      text: (item?.doseNumber ?? 1).toString(),
    );
    _totalDosesController = TextEditingController(
      text: (item?.totalDoses ?? 1).toString(),
    );
    _laboratoryController = TextEditingController(text: item?.laboratory ?? '');
    _lotController = TextEditingController(text: item?.lotNumber ?? '');
    _centerController = TextEditingController(
      text: item?.vaccinationCenter ?? '',
    );
    _professionalController = TextEditingController(
      text: item?.professional ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _applicationDate = item?.applicationDate ?? DateTime.now();
    _nextDoseDate = item?.nextDoseDate;
    _attachments = List<VaccineAttachment>.from(
      item?.attachments ?? <VaccineAttachment>[],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diseaseController.dispose();
    _doseController.dispose();
    _totalDosesController.dispose();
    _laboratoryController.dispose();
    _lotController.dispose();
    _centerController.dispose();
    _professionalController.dispose();
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
      final List<VaccineAttachment> files =
          await VaccineFileService.pickAndCopyFiles();
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

  Future<void> _removeAttachment(VaccineAttachment attachment) async {
    setState(() => _attachments.remove(attachment));
    await VaccineFileService.deletePhysicalFile(attachment);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final VaccineRecord item = VaccineRecord(
        id: widget.item?.id ?? _uuid.v4(),
        vaccineName: _nameController.text.trim(),
        preventsDisease: _diseaseController.text.trim(),
        applicationDate: _applicationDate,
        doseNumber: int.parse(_doseController.text.trim()),
        totalDoses: int.parse(_totalDosesController.text.trim()),
        laboratory: _laboratoryController.text.trim(),
        lotNumber: _lotController.text.trim(),
        vaccinationCenter: _centerController.text.trim(),
        professional: _professionalController.text.trim(),
        notes: _notesController.text.trim(),
        nextDoseDate: _nextDoseDate,
        attachments: List<VaccineAttachment>.from(_attachments),
      );
      await VaccineStorageService.upsert(item);
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
        title: Text(widget.item == null ? 'Nueva vacuna' : 'Editar vacuna'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la vacuna',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diseaseController,
              decoration: const InputDecoration(
                labelText: 'Enfermedad que previene',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Fecha de aplicación',
              value: _applicationDate,
              onTap: () async {
                final DateTime? selected = await _pickDate(_applicationDate);
                if (selected != null) {
                  setState(() => _applicationDate = selected);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _doseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'N.º de dosis',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveInteger,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _totalDosesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total del esquema',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveInteger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _laboratoryController,
              decoration: const InputDecoration(
                labelText: 'Laboratorio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lotController,
              decoration: const InputDecoration(
                labelText: 'Número de lote',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _centerController,
              decoration: const InputDecoration(
                labelText: 'Centro de vacunación',
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
            _DateField(
              label: 'Próxima dosis o refuerzo',
              value: _nextDoseDate,
              allowClear: true,
              onClear: () => setState(() => _nextDoseDate = null),
              onTap: () async {
                final DateTime? selected = await _pickDate(
                  _nextDoseDate ?? DateTime.now(),
                );
                if (selected != null) {
                  setState(() => _nextDoseDate = selected);
                }
              },
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
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Comprobantes (${_attachments.length})',
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
                  child: Text('No hay comprobantes adjuntos.'),
                ),
              )
            else
              ..._attachments.map(
                (VaccineAttachment attachment) => Card(
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
              label: Text(_saving ? 'Guardando...' : 'Guardar vacuna'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;

  String? _positiveInteger(String? value) {
    final int? parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 1 ? 'Ingresá un número válido.' : null;
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
