import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/profile/models/blood_type.dart';
import 'package:misalud_vortexit/features/profile/models/medical_profile.dart';
import 'package:misalud_vortexit/features/profile/services/medical_profile_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda perfiles diferentes para cada integrante', () async {
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

    await MedicalProfileStorageService.saveProfile(
      const MedicalProfile(
        fullName: 'Titular',
        documentNumber: '11111111',
        bloodType: BloodType.aPositive,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(MedicalProfileStorageService.loadProfile().fullName, isEmpty);

    await MedicalProfileStorageService.saveProfile(
      const MedicalProfile(
        fullName: 'Segundo integrante',
        documentNumber: '22222222',
        bloodType: BloodType.oPositive,
      ),
    );

    expect(
      MedicalProfileStorageService.loadProfile().fullName,
      'Segundo integrante',
    );

    await FamilyStorageService.setActiveMember(members.first.id);

    expect(MedicalProfileStorageService.loadProfile().fullName, 'Titular');
  });

  test('Elimina solamente el perfil activo', () async {
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

    await MedicalProfileStorageService.saveProfile(
      const MedicalProfile(fullName: 'Titular'),
    );

    await FamilyStorageService.setActiveMember(secondId);

    await MedicalProfileStorageService.saveProfile(
      const MedicalProfile(fullName: 'Segundo integrante'),
    );

    await MedicalProfileStorageService.deleteProfile();

    expect(MedicalProfileStorageService.loadProfile().fullName, isEmpty);

    await FamilyStorageService.setActiveMember(members.first.id);

    expect(MedicalProfileStorageService.loadProfile().fullName, 'Titular');
  });
}
