import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/vaccines/models/vaccine_item.dart';
import 'package:misalud_vortexit/features/vaccines/services/vaccine_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda y recupera una vacuna', () async {
    final DateTime now = DateTime.now();

    final VaccineItem item = VaccineItem(
      id: '1',
      name: 'Antigripal',
      dose: 'Refuerzo anual',
      applicationDate: DateTime(2026, 4, 10),
      lotNumber: 'LOTE123',
      applicationPlace: 'Centro de salud',
      professional: 'Enfermería',
      createdAt: now,
      updatedAt: now,
    );

    await VaccineStorageService.saveItem(item);

    final List<VaccineItem> restored = VaccineStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.name, 'Antigripal');
    expect(restored.first.lotNumber, 'LOTE123');
  });

  test('Mantiene vacunas separadas por integrante', () async {
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

    await VaccineStorageService.saveItem(
      VaccineItem(
        id: 'first',
        name: 'Vacuna del primer integrante',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(VaccineStorageService.loadItems(), isEmpty);

    await VaccineStorageService.saveItem(
      VaccineItem(
        id: 'second',
        name: 'Vacuna del segundo integrante',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      VaccineStorageService.loadItems().first.name,
      'Vacuna del segundo integrante',
    );
  });

  test('Elimina una vacuna', () async {
    final DateTime now = DateTime.now();

    final VaccineItem item = VaccineItem(
      id: 'delete',
      name: 'Vacuna temporal',
      createdAt: now,
      updatedAt: now,
    );

    await VaccineStorageService.saveItem(item);
    await VaccineStorageService.deleteItem(item.id);

    expect(VaccineStorageService.loadItems(), isEmpty);
  });
}
