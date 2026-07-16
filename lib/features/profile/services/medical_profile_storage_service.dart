import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/medical_profile.dart';

class MedicalProfileStorageService {
  MedicalProfileStorageService._();

  static const String _baseProfileKey = 'medical_profile';

  static String get _profileKey =>
      FamilyStorageService.scopedKey(_baseProfileKey);

  static MedicalProfile loadProfile() {
    final String? storedProfile = AppStorage.readString(_profileKey);

    if (storedProfile == null || storedProfile.trim().isEmpty) {
      return MedicalProfile.empty();
    }

    try {
      return MedicalProfile.fromJson(storedProfile);
    } on FormatException {
      return MedicalProfile.empty();
    }
  }

  static Future<MedicalProfile> saveProfile(MedicalProfile profile) async {
    final MedicalProfile updatedProfile = profile.copyWith(
      updatedAt: DateTime.now(),
    );

    final bool saved = await AppStorage.saveString(
      _profileKey,
      updatedProfile.toJson(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar el perfil médico.');
    }

    return updatedProfile;
  }

  static Future<void> deleteProfile() async {
    final bool removed = await AppStorage.remove(_profileKey);

    if (!removed && AppStorage.containsKey(_profileKey)) {
      throw StateError('No fue posible eliminar el perfil médico.');
    }
  }

  static bool hasProfile() {
    return AppStorage.containsKey(_profileKey);
  }
}
