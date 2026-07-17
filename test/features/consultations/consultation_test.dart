import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/consultations/models/consultation_item.dart';
import 'package:misalud_vortexit/features/consultations/services/consultation_storage_service.dart';
import 'package:misalud_vortexit/features/diagnoses/models/diagnosis_entry.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda una consulta con diagnóstico nomenclado', () async {
    final DateTime now = DateTime.now();

    final ConsultationItem item = ConsultationItem(
      id: '1',
      consultationDateTime: now,
      doctorId: 'doctor-1',
      doctorNameSnapshot: 'Dr. Juan Pérez',
      reason: 'Control de presión',
      diagnoses: <DiagnosisEntry>[
        DiagnosisEntry(
          id: 'diagnosis-1',
          primarySystem: DiagnosisSystem.icd11,
          primaryCode: 'BA00',
          description: 'Hipertensión esencial',
          icd10Code: 'I10',
          status: DiagnosisStatus.chronic,
          origin: DiagnosisOrigin.doctorConfirmed,
          diagnosisDate: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await ConsultationStorageService.saveItem(item);

    final List<ConsultationItem> restored =
        ConsultationStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.diagnoses, hasLength(1));
    expect(restored.first.diagnoses.first.primaryCode, 'BA00');
    expect(restored.first.diagnoses.first.icd10Code, 'I10');
  });

  test('Mantiene consultas separadas por integrante', () async {
    final List<FamilyMember> members = FamilyStorageService.loadMembers();
    final DateTime now = DateTime.now();

    const String secondId = 'second_member';

    await FamilyStorageService.saveMember(
      FamilyMember(
        id: secondId,
        name: 'Segundo integrante',
        relationship: 'Familia',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(members.first.id);

    await ConsultationStorageService.saveItem(
      ConsultationItem(
        id: 'first',
        consultationDateTime: now,
        reason: 'Consulta titular',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(ConsultationStorageService.loadItems(), isEmpty);
  });
}
