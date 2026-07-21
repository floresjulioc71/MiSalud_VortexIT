import 'dart:convert';

import 'package:crypto/crypto.dart';

class PinHasher {
  const PinHasher._();

  static String hash(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  static bool verify({required String pin, required String hash}) {
    return PinHasher.hash(pin) == hash;
  }
}
