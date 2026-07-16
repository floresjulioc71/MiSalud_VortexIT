import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/surgeries/models/surgery_item.dart';
import 'package:misalud_vortexit/features/surgeries/services/surgery_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda y recupera una cirugía', () async {
    final DateTime now = DateTime.now();

    final SurgeryItem item = SurgeryItem(
      id: '1',
      procedure: 'Apendicectomía',
      surgeryDate: DateTime(2020, 4, 10),
      hospital: 'Hospital de prueba',
      surgeon: 'Dr. Prueba',
      reason: 'Apendicitis',
      createdAt: now,
      updatedAt: now,
    );

    await SurgeryStorageService.saveItem(item);

    final List<SurgeryItem> restored = SurgeryStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.procedure, 'Apendicectomía');
    expect(restored.first.hospital, 'Hospital de prueba');
  });

  test('Mantiene cirugías separadas por integrante', () async {
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

    await SurgeryStorageService.saveItem(
      SurgeryItem(
        id: 'first',
        procedure: 'Cirugía del primer integrante',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(SurgeryStorageService.loadItems(), isEmpty);

    await SurgeryStorageService.saveItem(
      SurgeryItem(
        id: 'second',
        procedure: 'Cirugía del segundo integrante',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      SurgeryStorageService.loadItems().first.procedure,
      'Cirugía del segundo integrante',
    );
  });

  test('Elimina una cirugía', () async {
    final DateTime now = DateTime.now();

    final SurgeryItem item = SurgeryItem(
      id: 'delete',
      procedure: 'Cirugía temporal',
      createdAt: now,
      updatedAt: now,
    );

    await SurgeryStorageService.saveItem(item);
    await SurgeryStorageService.deleteItem(item.id);

    expect(SurgeryStorageService.loadItems(), isEmpty);
  });
}
