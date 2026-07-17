import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../diagnoses/models/diagnosis_entry.dart';
import '../models/consultation_item.dart';
import '../services/consultation_storage_service.dart';
import 'consultation_edit_screen.dart';
import 'consultation_timeline_screen.dart';
import 'widgets/empty_consultation_state.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  List<ConsultationItem> _items = <ConsultationItem>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final List<ConsultationItem> items = ConsultationStorageService.loadItems();

    items.sort(
      (ConsultationItem a, ConsultationItem b) =>
          b.consultationDateTime.compareTo(a.consultationDateTime),
    );

    setState(() {
      _items = items;
    });
  }

  Future<void> _openEditor([ConsultationItem? item]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => ConsultationEditScreen(item: item),
      ),
    );

    if (changed == true && mounted) {
      _reload();
    }
  }

  Future<void> _openTimeline() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const ConsultationTimelineScreen(),
      ),
    );

    if (mounted) {
      _reload();
    }
  }

  Future<void> _deleteItem(ConsultationItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar consulta'),
          content: const Text(
            'Se eliminará la consulta y sus diagnósticos asociados.',
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

    await ConsultationStorageService.deleteItem(item.id);

    if (!mounted) {
      return;
    }

    _reload();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Consulta eliminada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultas médicas'),
        actions: [
          IconButton(
            tooltip: 'Evolución clínica',
            onPressed: _items.isEmpty ? null : _openTimeline,
            icon: const Icon(Icons.timeline_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(AppIcons.add),
        label: const Text('Agregar'),
      ),
      body: _items.isEmpty
          ? EmptyConsultationState(onAdd: () => _openEditor())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.large,
                    AppSpacing.large,
                    AppSpacing.large,
                    0,
                  ),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.timeline_outlined),
                      title: const Text('Evolución clínica'),
                      subtitle: const Text(
                        'Ver consultas en una línea de tiempo con búsqueda y filtros.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openTimeline,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.medium),
                    itemBuilder: (BuildContext context, int index) {
                      final ConsultationItem item = _items[index];

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(
                            AppSpacing.large,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(Icons.event_note_outlined),
                          ),
                          title: Text(
                            _formatDateTime(item.consultationDateTime),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.small,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.doctorNameSnapshot.isNotEmpty)
                                  Text(
                                    item.specialtySnapshot.isEmpty
                                        ? item.doctorNameSnapshot
                                        : '${item.doctorNameSnapshot} • '
                                              '${item.specialtySnapshot}',
                                  ),
                                if (item.reason.isNotEmpty)
                                  Text('Motivo: ${item.reason}'),
                                if (item.diagnoses.isNotEmpty)
                                  Text(
                                    'Diagnósticos: '
                                    '${item.diagnoses.map((DiagnosisEntry diagnosis) => diagnosis.description).join(', ')}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                ),
              ],
            ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}
