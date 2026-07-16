import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/medical_history/models/medical_history_item.dart';
import 'package:misalud_vortexit/features/medical_history/services/medical_history_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda datos separados por persona', () async {
    final DateTime now = DateTime.now();
    final MedicalHistoryItem item = MedicalHistoryItem(
      id: '1',
      title: 'Hipertensión',
      createdAt: now,
      updatedAt: now,
    );

    await MedicalHistoryStorageService.saveItem(item);
    final List<MedicalHistoryItem> restored =
        MedicalHistoryStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.title, 'Hipertensión');
  });
}
