import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/profile/models/blood_type.dart';
import 'package:misalud_vortexit/features/profile/models/medical_profile.dart';
import 'package:misalud_vortexit/features/profile/services/medical_profile_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
  });

  test('El perfil vacío se identifica correctamente', () {
    final MedicalProfile profile = MedicalProfile.empty();

    expect(profile.isEmpty, isTrue);
    expect(profile.bloodType, BloodType.unknown);
  });

  test('El perfil se convierte a JSON y se restaura', () {
    final MedicalProfile profile = MedicalProfile(
      fullName: 'Julio Flores',
      documentNumber: '12345678',
      birthDate: DateTime(1972, 1, 10),
      bloodType: BloodType.oPositive,
      healthInsurance: 'Obra Social',
      membershipNumber: 'ABC123',
      emergencyContactName: 'Contacto',
      emergencyContactPhone: '2610000000',
      notes: 'Sin observaciones',
    );

    final MedicalProfile restored = MedicalProfile.fromJson(profile.toJson());

    expect(restored.fullName, 'Julio Flores');
    expect(restored.documentNumber, '12345678');
    expect(restored.birthDate, DateTime(1972, 1, 10));
    expect(restored.bloodType, BloodType.oPositive);
    expect(restored.healthInsurance, 'Obra Social');
    expect(restored.membershipNumber, 'ABC123');
    expect(restored.emergencyContactName, 'Contacto');
    expect(restored.emergencyContactPhone, '2610000000');
    expect(restored.notes, 'Sin observaciones');
  });

  test('El perfil se guarda y se recupera localmente', () async {
    const MedicalProfile profile = MedicalProfile(
      fullName: 'Persona de prueba',
      bloodType: BloodType.aPositive,
    );

    final MedicalProfile saved = await MedicalProfileStorageService.saveProfile(
      profile,
    );

    final MedicalProfile restored = MedicalProfileStorageService.loadProfile();

    expect(saved.updatedAt, isNotNull);
    expect(restored.fullName, 'Persona de prueba');
    expect(restored.bloodType, BloodType.aPositive);
    expect(MedicalProfileStorageService.hasProfile(), isTrue);
  });

  test('El perfil almacenado puede eliminarse', () async {
    const MedicalProfile profile = MedicalProfile(fullName: 'Perfil temporal');

    await MedicalProfileStorageService.saveProfile(profile);
    await MedicalProfileStorageService.deleteProfile();

    expect(MedicalProfileStorageService.hasProfile(), isFalse);
    expect(MedicalProfileStorageService.loadProfile().isEmpty, isTrue);
  });
}
