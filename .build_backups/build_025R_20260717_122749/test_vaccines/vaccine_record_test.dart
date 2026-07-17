import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/vaccines/models/vaccine_record.dart';

void main() {
  test('calcula esquema completo', () {
    final VaccineRecord item = VaccineRecord(
      id: '1',
      vaccineName: 'Ejemplo',
      preventsDisease: '',
      applicationDate: DateTime(2026, 1, 1),
      doseNumber: 2,
      totalDoses: 2,
      laboratory: '',
      lotNumber: '',
      vaccinationCenter: '',
      professional: '',
      notes: '',
      nextDoseDate: null,
      attachments: const <VaccineAttachment>[],
    );

    expect(
      item.statusAt(DateTime(2026, 7, 17)),
      VaccineScheduleStatus.complete,
    );
  });

  test('detecta refuerzo vencido', () {
    final VaccineRecord item = VaccineRecord(
      id: '1',
      vaccineName: 'Ejemplo',
      preventsDisease: '',
      applicationDate: DateTime(2026, 1, 1),
      doseNumber: 1,
      totalDoses: 2,
      laboratory: '',
      lotNumber: '',
      vaccinationCenter: '',
      professional: '',
      notes: '',
      nextDoseDate: DateTime(2026, 7, 1),
      attachments: const <VaccineAttachment>[],
    );

    expect(item.statusAt(DateTime(2026, 7, 17)), VaccineScheduleStatus.overdue);
  });

  test('conserva datos al serializar', () {
    final VaccineRecord source = VaccineRecord(
      id: 'v1',
      vaccineName: 'Antigripal',
      preventsDisease: 'Influenza',
      applicationDate: DateTime(2026, 6, 1),
      doseNumber: 1,
      totalDoses: 1,
      laboratory: 'Lab',
      lotNumber: 'ABC123',
      vaccinationCenter: 'Centro',
      professional: 'Profesional',
      notes: 'Sin reacción',
      nextDoseDate: DateTime(2027, 6, 1),
      attachments: const <VaccineAttachment>[
        VaccineAttachment(
          id: 'a1',
          name: 'carnet.pdf',
          path: '/tmp/carnet.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 100,
        ),
      ],
    );

    final VaccineRecord restored = VaccineRecord.fromJson(source.toJson());

    expect(restored.vaccineName, source.vaccineName);
    expect(restored.lotNumber, source.lotNumber);
    expect(restored.attachments.single.isPdf, isTrue);
    expect(restored.nextDoseDate, source.nextDoseDate);
  });
}
