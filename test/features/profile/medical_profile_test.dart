import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
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

  test('Guarda el perfil de la persona activa', () async {
    const MedicalProfile profile = MedicalProfile(
      fullName: 'Persona de prueba',
      bloodType: BloodType.aPositive,
    );

    await MedicalProfileStorageService.saveProfile(profile);
    final MedicalProfile restored = MedicalProfileStorageService.loadProfile();

    expect(restored.fullName, 'Persona de prueba');
    expect(restored.bloodType, BloodType.aPositive);
  });
}
