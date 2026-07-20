import 'package:flutter/material.dart';

import '../models/clinical_document.dart';
import '../services/clinical_document_file_service.dart';
import '../services/clinical_document_storage_service.dart';

class ClinicalDocumentFormScreen extends StatefulWidget {
  final String memberId;
  final ClinicalDocument? document;
  const ClinicalDocumentFormScreen({
    super.key,
    required this.memberId,
    this.document,
  });

  @override
  State<ClinicalDocumentFormScreen> createState() =>
      _ClinicalDocumentFormScreenState();
}

class _ClinicalDocumentFormScreenState
    extends State<ClinicalDocumentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _professionalController;
  late final TextEditingController _institutionController;
  late final TextEditingController _notesController;
  late ClinicalDocumentType _type;
  late DateTime _documentDate;
  String _fileName = '';
  String _filePath = '';
  String _mimeType = '';
  bool _saving = false;
  bool _selectingFile = false;

  @override
  void initState() {
    super.initState();
    final ClinicalDocument? document = widget.document;
    _titleController = TextEditingController(text: document?.title ?? '');
    _professionalController = TextEditingController(
      text: document?.professional ?? '',
    );
    _institutionController = TextEditingController(
      text: document?.institution ?? '',
    );
    _notesController = TextEditingController(text: document?.notes ?? '');
    _type = document?.type ?? ClinicalDocumentType.prescription;
    _documentDate = document?.documentDate ?? DateTime.now();
    _fileName = document?.fileName ?? '';
    _filePath = document?.filePath ?? '';
    _mimeType = document?.mimeType ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _professionalController.dispose();
    _institutionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _documentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _documentDate = selected);
  }

  Future<void> _selectFile() async {
    setState(() => _selectingFile = true);
    try {
      final StoredClinicalFile? selected =
          await ClinicalDocumentFileService.pickAndStore(
            memberId: widget.memberId,
          );
      if (selected == null || !mounted) return;
      final String previousPath = _filePath;
      setState(() {
        _fileName = selected.fileName;
        _filePath = selected.filePath;
        _mimeType = selected.mimeType;
      });
      if (previousPath.isNotEmpty && previousPath != selected.filePath) {
        await ClinicalDocumentFileService.deleteStoredFile(previousPath);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo adjuntar el archivo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _selectingFile = false);
    }
  }

  Future<void> _removeFile() async {
    final String path = _filePath;
    setState(() {
      _fileName = '';
      _filePath = '';
      _mimeType = '';
    });
    await ClinicalDocumentFileService.deleteStoredFile(path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final DateTime now = DateTime.now();
    final ClinicalDocument? current = widget.document;
    final ClinicalDocument document = ClinicalDocument(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text,
      type: _type,
      documentDate: _documentDate,
      professional: _professionalController.text,
      institution: _institutionController.text,
      notes: _notesController.text,
      fileName: _fileName,
      filePath: _filePath,
      mimeType: _mimeType,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await ClinicalDocumentStorageService.saveItem(document);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.document == null ? 'Nuevo documento' : 'Editar documento',
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresá un título.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ClinicalDocumentType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: ClinicalDocumentType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha del documento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(_date(_documentDate)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _professionalController,
              decoration: const InputDecoration(
                labelText: 'Profesional',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'Institución',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Archivo adjunto',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_filePath.isEmpty)
              OutlinedButton.icon(
                onPressed: _selectingFile ? null : _selectFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _selectingFile ? 'Seleccionando...' : 'Adjuntar PDF o imagen',
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: Icon(
                    _mimeType == 'application/pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(
                    _fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_mimeType),
                  trailing: IconButton(
                    onPressed: _removeFile,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Guardar documento'),
            ),
          ],
        ),
      ),
    ),
  );
}
