import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/medical_history/models/medical_history_item.dart';
import 'package:misalud_vortexit/features/medical_history/services/medical_history_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
  });

  test('Guarda y recupera un antecedente médico', () async {
    final DateTime now = DateTime.now();

    final MedicalHistoryItem item = MedicalHistoryItem(
      id: '1',
      title: 'Hipertensión arterial',
      description: 'Diagnosticada en control clínico',
      diagnosisDate: DateTime(2020, 5, 10),
      status: MedicalHistoryStatus.controlled,
      notes: 'Control periódico',
      createdAt: now,
      updatedAt: now,
    );

    await MedicalHistoryStorageService.saveItem(item);

    final List<MedicalHistoryItem> restored =
        MedicalHistoryStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.title, 'Hipertensión arterial');
    expect(restored.first.status, MedicalHistoryStatus.controlled);
  });

  test('Elimina un antecedente médico', () async {
    final DateTime now = DateTime.now();

    final MedicalHistoryItem item = MedicalHistoryItem(
      id: '2',
      title: 'Antecedente temporal',
      createdAt: now,
      updatedAt: now,
    );

    await MedicalHistoryStorageService.saveItem(item);
    await MedicalHistoryStorageService.deleteItem(item.id);

    expect(MedicalHistoryStorageService.loadItems(), isEmpty);
  });
}
