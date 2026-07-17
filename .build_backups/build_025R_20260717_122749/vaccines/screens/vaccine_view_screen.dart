import 'dart:io';

import 'package:flutter/material.dart';

import '../models/vaccine_record.dart';
import '../services/vaccine_file_service.dart';

class VaccineViewScreen extends StatelessWidget {
  final VaccineRecord item;

  const VaccineViewScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final VaccineScheduleStatus status = item.statusAt(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(item.vaccineName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _row(Icons.shield_outlined, 'Estado', status.label),
                  _row(
                    Icons.calendar_month_outlined,
                    'Aplicación',
                    _date(item.applicationDate),
                  ),
                  _row(
                    Icons.format_list_numbered,
                    'Dosis',
                    '${item.doseNumber} de ${item.totalDoses}',
                  ),
                  if (item.preventsDisease.isNotEmpty)
                    _row(
                      Icons.health_and_safety_outlined,
                      'Previene',
                      item.preventsDisease,
                    ),
                  if (item.laboratory.isNotEmpty)
                    _row(
                      Icons.science_outlined,
                      'Laboratorio',
                      item.laboratory,
                    ),
                  if (item.lotNumber.isNotEmpty)
                    _row(Icons.numbers, 'Lote', item.lotNumber),
                  if (item.vaccinationCenter.isNotEmpty)
                    _row(
                      Icons.local_hospital_outlined,
                      'Centro',
                      item.vaccinationCenter,
                    ),
                  if (item.professional.isNotEmpty)
                    _row(
                      Icons.medical_services_outlined,
                      'Profesional',
                      item.professional,
                    ),
                  if (item.nextDoseDate != null)
                    _row(
                      Icons.event_repeat_outlined,
                      'Próxima dosis',
                      _date(item.nextDoseDate!),
                    ),
                  if (item.notes.isNotEmpty)
                    _row(Icons.notes_outlined, 'Observaciones', item.notes),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Comprobantes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (item.attachments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Esta vacuna no tiene comprobantes adjuntos.'),
              ),
            )
          else
            ...item.attachments.map(
              (VaccineAttachment attachment) => Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (attachment.isImage &&
                        File(attachment.path).existsSync())
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.file(
                          File(attachment.path),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ListTile(
                      leading: Icon(
                        attachment.isPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                      ),
                      title: Text(attachment.name),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => VaccineFileService.open(attachment),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
