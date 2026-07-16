import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/allergies/models/allergy_item.dart';
import 'package:misalud_vortexit/features/allergies/services/allergy_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda datos separados por persona', () async {
    final DateTime now = DateTime.now();
    final AllergyItem item = AllergyItem(
      id: '1',
      allergen: 'Penicilina',
      type: AllergyType.medication,
      severity: AllergySeverity.severe,
      createdAt: now,
      updatedAt: now,
    );

    await AllergyStorageService.saveItem(item);
    final List<AllergyItem> restored = AllergyStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.allergen, 'Penicilina');
  });
}
