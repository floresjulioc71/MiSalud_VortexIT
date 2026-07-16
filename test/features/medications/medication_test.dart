import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/medications/models/medication_item.dart';
import 'package:misalud_vortexit/features/medications/services/medication_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda datos separados por persona', () async {
    final DateTime now = DateTime.now();
    final MedicationItem item = MedicationItem(
      id: '1',
      name: 'Losartán',
      createdAt: now,
      updatedAt: now,
    );

    await MedicationStorageService.saveItem(item);
    final List<MedicationItem> restored = MedicationStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.name, 'Losartán');
  });
}
