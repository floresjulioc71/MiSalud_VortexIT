import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../diagnoses/models/diagnosis_entry.dart';
import '../../diagnoses/models/diagnosis_library_item.dart';
import '../../diagnoses/services/consultation_diagnosis_library_service.dart';
import '../../diagnoses/services/diagnosis_library_service.dart';
import 'diagnosis_edit_screen.dart';

enum _DiagnosisAction { rename, delete }

class DiagnosisPickerScreen extends StatefulWidget {
  const DiagnosisPickerScreen({super.key});

  @override
  State<DiagnosisPickerScreen> createState() => _DiagnosisPickerScreenState();
}

class _DiagnosisPickerScreenState extends State<DiagnosisPickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<DiagnosisLibraryItem> _entries = <DiagnosisLibraryItem>[];
  List<DiagnosisLibraryItem> _results = <DiagnosisLibraryItem>[];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    try {
      final List<DiagnosisLibraryItem> entries =
          await ConsultationDiagnosisLibraryService.loadItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _results = ConsultationDiagnosisLibraryService.search(
          entries,
          _searchController.text,
        );
        _loading = false;
        _loadError = null;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadError = error.toString();
      });
    }
  }

  void _search(String value) {
    setState(() {
      _results = ConsultationDiagnosisLibraryService.search(_entries, value);
    });
  }

  Future<void> _createDiagnosis() async {
    final DiagnosisEntry? result = await Navigator.of(context)
        .push<DiagnosisEntry>(
          MaterialPageRoute<DiagnosisEntry>(
            builder: (BuildContext context) => DiagnosisEditScreen(
              initialDescription: _searchController.text.trim(),
            ),
          ),
        );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _renameDiagnosis(DiagnosisLibraryItem item) async {
    final TextEditingController controller = TextEditingController(
      text: item.description,
    );

    final String? newDescription = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? validationMessage;

        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  title: const Text('Renombrar diagnóstico'),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      errorText: validationMessage,
                    ),
                    onSubmitted: (String value) {
                      final String cleanValue = value.trim();

                      if (cleanValue.isEmpty) {
                        setDialogState(() {
                          validationMessage = 'La descripción es obligatoria.';
                        });
                        return;
                      }

                      Navigator.of(dialogContext).pop(cleanValue);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final String cleanValue = controller.text.trim();

                        if (cleanValue.isEmpty) {
                          setDialogState(() {
                            validationMessage =
                                'La descripción es obligatoria.';
                          });
                          return;
                        }

                        Navigator.of(dialogContext).pop(cleanValue);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
        );
      },
    );

    controller.dispose();

    if (newDescription == null || !mounted) {
      return;
    }

    final bool renamed = await DiagnosisLibraryService.renameItem(
      item.id,
      newDescription,
    );

    if (!mounted) {
      return;
    }

    if (!renamed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo renombrar. Puede existir otro diagnóstico con ese nombre.',
            ),
          ),
        );
      return;
    }

    await _loadLibrary();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Diagnóstico actualizado.')));
  }

  Future<void> _deleteDiagnosis(DiagnosisLibraryItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar diagnóstico'),
          content: Text(
            '¿Eliminar "${item.description}" de la biblioteca?\n\n'
            'Las consultas ya guardadas no se modificarán.',
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

    final bool deleted = await DiagnosisLibraryService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el diagnóstico.')),
        );
      return;
    }

    await _loadLibrary();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Diagnóstico eliminado.')));
  }

  Future<void> _handleAction(
    _DiagnosisAction action,
    DiagnosisLibraryItem item,
  ) async {
    switch (action) {
      case _DiagnosisAction.rename:
        await _renameDiagnosis(item);
        return;
      case _DiagnosisAction.delete:
        await _deleteDiagnosis(item);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim();
    final bool canCreate =
        !_loading &&
        query.isNotEmpty &&
        !ConsultationDiagnosisLibraryService.containsDescription(
          _entries,
          query,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar diagnóstico'),
        actions: [
          IconButton(
            tooltip: 'Crear diagnóstico',
            onPressed: _loading ? null : _createDiagnosis,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              enabled: !_loading && _loadError == null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _search,
              onSubmitted: (_) {
                if (canCreate) {
                  _createDiagnosis();
                }
              },
              decoration: InputDecoration(
                labelText: 'Escribir diagnóstico',
                prefixIcon: const Icon(Icons.search),
                helperText: _loading
                    ? 'Cargando biblioteca global...'
                    : '${_entries.length} diagnósticos en la biblioteca global',
              ),
            ),
          ),
          if (canCreate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: Text('Agregar "$query"'),
                  subtitle: const Text('Se guardará al registrar la consulta.'),
                  onTap: _createDiagnosis,
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: AppSpacing.medium),
                          const Text(
                            'No se pudo cargar la biblioteca.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          FilledButton(
                            onPressed: _loadLibrary,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? 'Escribí un diagnóstico para comenzar.'
                          : 'No hay coincidencias.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DiagnosisLibraryItem item = _results[index];

                      return ListTile(
                        leading: const Icon(Icons.medical_information_outlined),
                        title: Text(item.description),
                        subtitle: Text(
                          item.useCount == 1
                              ? 'Usado en 1 consulta'
                              : 'Usado en ${item.useCount} consultas',
                        ),
                        trailing: PopupMenuButton<_DiagnosisAction>(
                          tooltip: 'Opciones',
                          onSelected: (_DiagnosisAction action) {
                            _handleAction(action, item);
                          },
                          itemBuilder: (BuildContext context) => const [
                            PopupMenuItem<_DiagnosisAction>(
                              value: _DiagnosisAction.rename,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Renombrar'),
                              ),
                            ),
                            PopupMenuItem<_DiagnosisAction>(
                              value: _DiagnosisAction.delete,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Eliminar'),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop(
                            ConsultationDiagnosisLibraryService.toDiagnosisEntry(
                              item,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
