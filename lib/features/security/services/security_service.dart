import '../models/security_settings.dart';
import 'pin_hasher.dart';
import 'pin_storage_service.dart';

class SecurityService {
  const SecurityService._();

  static const int maximumFailedAttempts = 5;

  static Future<void> createPin(String pin) async {
    _validatePin(pin);

    final String hash = PinHasher.hash(pin);

    await PinStorageService.savePinHash(hash);
    await PinStorageService.resetAttempts();
  }

  static bool hasPin() {
    return PinStorageService.isPinEnabled();
  }

  static bool verifyPin(String pin) {
    final String? storedHash = PinStorageService.readPinHash();

    if (storedHash == null || storedHash.isEmpty) {
      return false;
    }

    return PinHasher.verify(pin: pin, hash: storedHash);
  }

  static Future<bool> authenticate(String pin) async {
    final bool isValid = verifyPin(pin);

    if (isValid) {
      await PinStorageService.resetAttempts();
      return true;
    }

    final int attempts = PinStorageService.failedAttempts() + 1;

    await PinStorageService.setFailedAttempts(attempts);

    return false;
  }

  static int failedAttempts() {
    return PinStorageService.failedAttempts();
  }

  static int remainingAttempts() {
    final int remaining =
        maximumFailedAttempts - PinStorageService.failedAttempts();

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  static bool hasReachedMaximumAttempts() {
    return failedAttempts() >= maximumFailedAttempts;
  }

  static Future<void> resetFailedAttempts() async {
    await PinStorageService.resetAttempts();
  }

  static Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    _validatePin(newPin);

    if (!verifyPin(oldPin)) {
      throw const SecurityException('El PIN actual es incorrecto.');
    }

    await createPin(newPin);
  }

  static Future<void> removePin() async {
    await PinStorageService.disablePin();
    await PinStorageService.resetAttempts();
  }

  static SecuritySettings settings() {
    return SecuritySettings(
      pinEnabled: PinStorageService.isPinEnabled(),
      biometricEnabled: PinStorageService.biometricEnabled(),
      failedAttempts: PinStorageService.failedAttempts(),
    );
  }

  static void _validatePin(String pin) {
    final RegExp validPin = RegExp(r'^\d{4}$');

    if (!validPin.hasMatch(pin)) {
      throw const SecurityException(
        'El PIN debe contener exactamente 4 dígitos.',
      );
    }
  }
}

class SecurityException implements Exception {
  final String message;

  const SecurityException(this.message);

  @override
  String toString() => message;
}
