import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/allergies/models/allergy_item.dart';
import 'package:misalud_vortexit/features/allergies/services/allergy_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
  });

  test('Guarda y recupera una alergia', () async {
    final DateTime now = DateTime.now();

    final AllergyItem item = AllergyItem(
      id: '1',
      allergen: 'Penicilina',
      type: AllergyType.medication,
      severity: AllergySeverity.severe,
      reaction: 'Dificultad respiratoria',
      notes: 'Evitar derivados',
      createdAt: now,
      updatedAt: now,
    );

    await AllergyStorageService.saveItem(item);

    final List<AllergyItem> restored = AllergyStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.allergen, 'Penicilina');
    expect(restored.first.type, AllergyType.medication);
    expect(restored.first.severity, AllergySeverity.severe);
  });

  test('Elimina una alergia', () async {
    final DateTime now = DateTime.now();

    final AllergyItem item = AllergyItem(
      id: '2',
      allergen: 'Alergia temporal',
      type: AllergyType.other,
      severity: AllergySeverity.mild,
      createdAt: now,
      updatedAt: now,
    );

    await AllergyStorageService.saveItem(item);
    await AllergyStorageService.deleteItem(item.id);

    expect(AllergyStorageService.loadItems(), isEmpty);
  });
}
