import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/medications/models/medication_item.dart';
import 'package:misalud_vortexit/features/medications/services/medication_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
  });

  test('Guarda y recupera un medicamento', () async {
    final DateTime now = DateTime.now();

    final MedicationItem item = MedicationItem(
      id: '1',
      name: 'Losartán',
      activeIngredient: 'Losartán potásico',
      dose: '50 mg',
      frequency: 'Una vez al día',
      schedule: '08:00',
      route: MedicationRoute.oral,
      startDate: DateTime(2024, 1, 1),
      status: MedicationStatus.active,
      prescribedBy: 'Dr. Prueba',
      createdAt: now,
      updatedAt: now,
    );

    await MedicationStorageService.saveItem(item);

    final List<MedicationItem> restored = MedicationStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.name, 'Losartán');
    expect(restored.first.route, MedicationRoute.oral);
    expect(restored.first.status, MedicationStatus.active);
  });

  test('Elimina un medicamento', () async {
    final DateTime now = DateTime.now();

    final MedicationItem item = MedicationItem(
      id: '2',
      name: 'Medicamento temporal',
      createdAt: now,
      updatedAt: now,
    );

    await MedicationStorageService.saveItem(item);
    await MedicationStorageService.deleteItem(item.id);

    expect(MedicationStorageService.loadItems(), isEmpty);
  });
}
