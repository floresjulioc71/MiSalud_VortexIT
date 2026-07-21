import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class ChecksumService {
  const ChecksumService();

  String calculateFromBytes(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  String calculateFromString(String value) {
    return calculateFromBytes(utf8.encode(value));
  }

  String calculateFromJson(Map<String, dynamic> json) {
    final String encodedJson = jsonEncode(json);
    return calculateFromString(encodedJson);
  }

  bool verifyBytes({
    required List<int> bytes,
    required String expectedChecksum,
  }) {
    final String calculatedChecksum = calculateFromBytes(bytes);

    return calculatedChecksum.toLowerCase() ==
        expectedChecksum.trim().toLowerCase();
  }

  bool verifyString({required String value, required String expectedChecksum}) {
    return verifyBytes(
      bytes: utf8.encode(value),
      expectedChecksum: expectedChecksum,
    );
  }

  bool verifyJson({
    required Map<String, dynamic> json,
    required String expectedChecksum,
  }) {
    return verifyString(
      value: jsonEncode(json),
      expectedChecksum: expectedChecksum,
    );
  }

  Uint8List encodeString(String value) {
    return Uint8List.fromList(utf8.encode(value));
  }
}
