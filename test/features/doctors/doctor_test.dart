import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/doctors/models/doctor_item.dart';
import 'package:misalud_vortexit/features/doctors/services/doctor_storage_service.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda y recupera un médico', () async {
    final DateTime now = DateTime.now();

    final DoctorItem item = DoctorItem(
      id: '1',
      firstName: 'Juan',
      lastName: 'Pérez',
      specialty: 'Cardiología',
      institution: 'Hospital de prueba',
      isPrimaryDoctor: true,
      createdAt: now,
      updatedAt: now,
    );

    await DoctorStorageService.saveItem(item);

    final List<DoctorItem> restored = DoctorStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.fullName, 'Juan Pérez');
    expect(restored.first.isPrimaryDoctor, isTrue);
  });

  test('Solo conserva un médico de cabecera', () async {
    final DateTime now = DateTime.now();

    await DoctorStorageService.saveItem(
      DoctorItem(
        id: '1',
        firstName: 'Primer',
        lastName: 'Médico',
        isPrimaryDoctor: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await DoctorStorageService.saveItem(
      DoctorItem(
        id: '2',
        firstName: 'Segundo',
        lastName: 'Médico',
        isPrimaryDoctor: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final List<DoctorItem> restored = DoctorStorageService.loadItems();

    expect(
      restored.where((DoctorItem item) => item.isPrimaryDoctor),
      hasLength(1),
    );
    expect(restored.first.id, '2');
  });

  test('Mantiene médicos separados por integrante', () async {
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

    await DoctorStorageService.saveItem(
      DoctorItem(
        id: 'first',
        firstName: 'Médico',
        lastName: 'Primero',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(DoctorStorageService.loadItems(), isEmpty);
  });

  test('Elimina un médico', () async {
    final DateTime now = DateTime.now();

    final DoctorItem item = DoctorItem(
      id: 'delete',
      firstName: 'Temporal',
      lastName: 'Prueba',
      createdAt: now,
      updatedAt: now,
    );

    await DoctorStorageService.saveItem(item);
    await DoctorStorageService.deleteItem(item.id);

    expect(DoctorStorageService.loadItems(), isEmpty);
  });
}
