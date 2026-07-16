import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Crea una persona inicial activa', () {
    final List<FamilyMember> members = FamilyStorageService.loadMembers();
    expect(members, hasLength(1));
    expect(FamilyStorageService.activeMemberId, members.first.id);
  });

  test('Separa las claves por integrante', () async {
    final String firstId = FamilyStorageService.activeMemberId;
    final DateTime now = DateTime.now();
    const String secondId = 'member_2';

    await FamilyStorageService.saveMember(
      FamilyMember(
        id: secondId,
        name: 'Segundo integrante',
        relationship: 'Familia',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(firstId);
    final String firstKey = FamilyStorageService.scopedKey('medical_profile');

    await FamilyStorageService.setActiveMember(secondId);
    final String secondKey = FamilyStorageService.scopedKey('medical_profile');

    expect(firstKey, isNot(secondKey));
  });
}
