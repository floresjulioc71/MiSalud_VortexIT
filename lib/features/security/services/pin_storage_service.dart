import '../../../core/storage/app_storage.dart';

class PinStorageService {
  const PinStorageService._();

  static const String _pinHashKey = 'security.pinHash';

  static const String _pinEnabledKey = 'security.pinEnabled';

  static const String _biometricEnabledKey = 'security.biometricEnabled';

  static const String _failedAttemptsKey = 'security.failedAttempts';

  static Future<void> savePinHash(String hash) async {
    await AppStorage.saveString(_pinHashKey, hash);

    await AppStorage.saveBool(_pinEnabledKey, true);
  }

  static String? readPinHash() {
    return AppStorage.readString(_pinHashKey);
  }

  static bool isPinEnabled() {
    return AppStorage.readBool(_pinEnabledKey) ?? false;
  }

  static Future<void> disablePin() async {
    await AppStorage.remove(_pinHashKey);

    await AppStorage.saveBool(_pinEnabledKey, false);
  }

  static bool biometricEnabled() {
    return AppStorage.readBool(_biometricEnabledKey) ?? false;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await AppStorage.saveBool(_biometricEnabledKey, enabled);
  }

  static int failedAttempts() {
    return AppStorage.readInt(_failedAttemptsKey) ?? 0;
  }

  static Future<void> setFailedAttempts(int attempts) async {
    await AppStorage.saveInt(_failedAttemptsKey, attempts);
  }

  static Future<void> resetAttempts() async {
    await setFailedAttempts(0);
  }
}
