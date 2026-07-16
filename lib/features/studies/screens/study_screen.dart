import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../models/study_item.dart';
import '../services/study_backup_service.dart';
import '../services/study_file_service.dart';
import '../services/study_report_service.dart';
import '../services/study_share_service.dart';
import '../services/study_storage_service.dart';
import 'study_viewer_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<StudyItem> _items = <StudyItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = StudyStorageService.loadItems();
    });
  }

  Future<void> _openEditor([StudyItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => StudyEditScreen(item: item),
      ),
    );

    if (changed == true) {
      _reload();
    }
  }

  Future<void> _openViewer(StudyItem item) async {
    if (item.attachmentPath == null) {
      _showMessage('Este estudio no tiene archivo adjunto.');
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => StudyViewerScreen(study: item),
      ),
    );
  }

  Future<void> _share(StudyItem item) async {
    try {
      await StudyShareService.share(item);
    } on Object catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    }
  }

  Future<void> _deleteItem(StudyItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar estudio'),
          content: Text('Se eliminará "${item.name}" y su archivo adjunto.'),
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

    await StudyFileService.deleteAttachment(item.attachmentPath);
    await StudyStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();
    _showMessage('Estudio eliminado.');
  }

  Future<void> _exportBackup() async {
    try {
      final File file = await StudyBackupService.exportBackup();

      if (!mounted) {
        return;
      }

      _showMessage('Respaldo creado en:\n${file.path}');
    } on Object catch (error) {
      if (mounted) {
        _showMessage('No fue posible crear el respaldo: $error');
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      final int count = await StudyBackupService.importBackup();

      if (!mounted) {
        return;
      }

      _reload();

      if (count > 0) {
        _showMessage('Se restauraron $count estudios.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('No fue posible restaurar: $error');
      }
    }
  }

  Future<void> _generateReport() async {
    try {
      final File file = await StudyReportService.generatePdf();

      if (!mounted) {
        return;
      }

      if (!Platform.isLinux) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(file.path)],
            subject: 'Informe de estudios médicos',
            title: 'Informe de estudios médicos',
          ),
        );
      }

      if (mounted) {
        _showMessage('Informe generado en:\n${file.path}');
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage('No fue posible generar el informe: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final Map<StudyCategory, List<StudyItem>> grouped =
        <StudyCategory, List<StudyItem>>{};

    for (final StudyItem item in _items) {
      grouped.putIfAbsent(item.category, () => <StudyItem>[]).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudios médicos'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (value == 'report') {
                _generateReport();
              } else if (value == 'backup') {
                _exportBackup();
              } else if (value == 'restore') {
                _importBackup();
              }
            },
            itemBuilder: (BuildContext context) {
              return const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'report',
                  child: Text('Generar informe PDF'),
                ),
                PopupMenuItem<String>(
                  value: 'backup',
                  child: Text('Exportar respaldo ZIP'),
                ),
                PopupMenuItem<String>(
                  value: 'restore',
                  child: Text('Restaurar respaldo ZIP'),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(AppIcons.add),
        label: const Text('Agregar'),
      ),
      body: _items.isEmpty
          ? _EmptyState(onAdd: () => _openEditor())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.large),
              children: grouped.entries.map((
                MapEntry<StudyCategory, List<StudyItem>> entry,
              ) {
                return _CategorySection(
                  category: entry.key,
                  studies: entry.value,
                  onOpen: _openViewer,
                  onEdit: _openEditor,
                  onShare: _share,
                  onDelete: _deleteItem,
                );
              }).toList(),
            ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final StudyCategory category;
  final List<StudyItem> studies;
  final ValueChanged<StudyItem> onOpen;
  final ValueChanged<StudyItem> onEdit;
  final ValueChanged<StudyItem> onShare;
  final ValueChanged<StudyItem> onDelete;

  const _CategorySection({
    required this.category,
    required this.studies,
    required this.onOpen,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.large),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(AppIcons.studies),
        title: Text(
          '${category.label} (${studies.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: studies.map((StudyItem item) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.small,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                item.attachmentType == StudyAttachmentType.pdf
                    ? Icons.picture_as_pdf_outlined
                    : item.attachmentType == StudyAttachmentType.image
                    ? Icons.image_outlined
                    : AppIcons.studies,
              ),
            ),
            title: Text(item.name),
            subtitle: Text(
              _subtitle(item),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'open') {
                  onOpen(item);
                } else if (value == 'edit') {
                  onEdit(item);
                } else if (value == 'share') {
                  onShare(item);
                } else if (value == 'delete') {
                  onDelete(item);
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  if (item.attachmentPath != null)
                    const PopupMenuItem<String>(
                      value: 'open',
                      child: Text('Ver archivo'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  if (item.attachmentPath != null)
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Text('Compartir'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
                ];
              },
            ),
            onTap: item.attachmentPath != null
                ? () => onOpen(item)
                : () => onEdit(item),
          );
        }).toList(),
      ),
    );
  }

  static String _subtitle(StudyItem item) {
    final List<String> parts = <String>[
      item.status.label,
      if (item.studyDate != null) _formatDate(item.studyDate!),
      if (item.institution.trim().isNotEmpty) item.institution,
      if (item.attachmentOriginalName != null) item.attachmentOriginalName!,
    ];

    return parts.join(' • ');
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class StudyEditScreen extends StatefulWidget {
  final StudyItem? item;

  const StudyEditScreen({super.key, this.item});

  @override
  State<StudyEditScreen> createState() => _StudyEditScreenState();
}

class _StudyEditScreenState extends State<StudyEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _doctorController;
  late final TextEditingController _institutionController;
  late final TextEditingController _resultController;
  late final TextEditingController _notesController;

  StudyCategory _category = StudyCategory.laboratory;
  StudyStatus _status = StudyStatus.completed;
  DateTime? _studyDate;
  StudyAttachmentResult? _newAttachment;
  bool _removeExistingAttachment = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final StudyItem? item = widget.item;

    _nameController = TextEditingController(text: item?.name ?? '');
    _doctorController = TextEditingController(
      text: item?.requestingDoctor ?? '',
    );
    _institutionController = TextEditingController(
      text: item?.institution ?? '',
    );
    _resultController = TextEditingController(text: item?.result ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _category = item?.category ?? StudyCategory.laboratory;
    _status = item?.status ?? StudyStatus.completed;
    _studyDate = item?.studyDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doctorController.dispose();
    _institutionController.dispose();
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStudyDate() async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _studyDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
      helpText: 'Fecha del estudio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _studyDate = selected;
    });
  }

  Future<void> _pickDocument() async {
    try {
      final StudyAttachmentResult? result =
          await StudyFileService.pickDocument();

      if (result != null && mounted) {
        setState(() {
          _newAttachment = result;
          _removeExistingAttachment = true;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    }
  }

  Future<void> _pickGalleryImage() async {
    try {
      final StudyAttachmentResult? result =
          await StudyFileService.pickImageFromGallery();

      if (result != null && mounted) {
        setState(() {
          _newAttachment = result;
          _removeExistingAttachment = true;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final StudyAttachmentResult? result = await StudyFileService.takePhoto();

      if (result != null && mounted) {
        setState(() {
          _newAttachment = result;
          _removeExistingAttachment = true;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        _showMessage(error.toString());
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final DateTime now = DateTime.now();
    final StudyItem? current = widget.item;

    String? attachmentPath = current?.attachmentPath;
    String? attachmentOriginalName = current?.attachmentOriginalName;
    StudyAttachmentType attachmentType =
        current?.attachmentType ?? StudyAttachmentType.none;

    if (_removeExistingAttachment &&
        current?.attachmentPath != null &&
        current!.attachmentPath != _newAttachment?.storedPath) {
      await StudyFileService.deleteAttachment(current.attachmentPath);
      attachmentPath = null;
      attachmentOriginalName = null;
      attachmentType = StudyAttachmentType.none;
    }

    if (_newAttachment != null) {
      attachmentPath = _newAttachment!.storedPath;
      attachmentOriginalName = _newAttachment!.originalName;
      attachmentType = _newAttachment!.type;
    }

    final StudyItem item = StudyItem(
      id: current?.id ?? now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _category,
      status: _status,
      studyDate: _studyDate,
      requestingDoctor: _doctorController.text.trim(),
      institution: _institutionController.text.trim(),
      result: _resultController.text.trim(),
      notes: _notesController.text.trim(),
      attachmentPath: attachmentPath,
      attachmentOriginalName: attachmentOriginalName,
      attachmentType: attachmentType,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    await StudyStorageService.saveItem(item);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final String? displayedAttachment =
        _newAttachment?.originalName ??
        (_removeExistingAttachment
            ? null
            : widget.item?.attachmentOriginalName);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nuevo estudio' : 'Editar estudio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del estudio',
                prefixIcon: Icon(AppIcons.studies),
              ),
              validator: (String? value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Ingresa el nombre del estudio.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<StudyCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: StudyCategory.values.map((StudyCategory category) {
                return DropdownMenuItem<StudyCategory>(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (StudyCategory? value) {
                setState(() {
                  _category = value ?? StudyCategory.other;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<StudyStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: StudyStatus.values.map((StudyStatus status) {
                return DropdownMenuItem<StudyStatus>(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: (StudyStatus? value) {
                setState(() {
                  _status = value ?? StudyStatus.completed;
                });
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectStudyDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _studyDate == null
                      ? 'No especificada'
                      : _CategorySection._formatDate(_studyDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _doctorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Médico solicitante',
                prefixIcon: Icon(AppIcons.doctors),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _institutionController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Institución',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _resultController,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Resultado o diagnóstico',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.fact_check_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Archivo adjunto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(displayedAttachment ?? 'Sin archivo adjunto'),
                    const SizedBox(height: AppSpacing.medium),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickDocument,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Adjuntar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickGalleryImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galería'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Cámara'),
                        ),
                        if (displayedAttachment != null)
                          OutlinedButton.icon(
                            onPressed: () async {
                              if (_newAttachment != null) {
                                await StudyFileService.deleteAttachment(
                                  _newAttachment!.storedPath,
                                );
                              }

                              if (mounted) {
                                setState(() {
                                  _newAttachment = null;
                                  _removeExistingAttachment = true;
                                });
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Quitar'),
                          ),
                      ],
                    ),
                  ],
                ),
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
              label: Text(_saving ? 'Guardando...' : 'Guardar estudio'),
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
            const Icon(AppIcons.studies, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Todavía no hay estudios registrados.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(AppIcons.add),
              label: const Text('Agregar estudio'),
            ),
          ],
        ),
      ),
    );
  }
}
