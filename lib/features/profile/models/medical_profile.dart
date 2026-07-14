import 'dart:convert';

import 'blood_type.dart';

class MedicalProfile {
  final String fullName;
  final String documentNumber;
  final DateTime? birthDate;
  final BloodType bloodType;
  final String healthInsurance;
  final String membershipNumber;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String notes;
  final DateTime? updatedAt;

  const MedicalProfile({
    this.fullName = '',
    this.documentNumber = '',
    this.birthDate,
    this.bloodType = BloodType.unknown,
    this.healthInsurance = '',
    this.membershipNumber = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.notes = '',
    this.updatedAt,
  });

  factory MedicalProfile.empty() {
    return const MedicalProfile();
  }

  bool get isEmpty {
    return fullName.trim().isEmpty &&
        documentNumber.trim().isEmpty &&
        birthDate == null &&
        bloodType == BloodType.unknown &&
        healthInsurance.trim().isEmpty &&
        membershipNumber.trim().isEmpty &&
        emergencyContactName.trim().isEmpty &&
        emergencyContactPhone.trim().isEmpty &&
        notes.trim().isEmpty;
  }

  MedicalProfile copyWith({
    String? fullName,
    String? documentNumber,
    DateTime? birthDate,
    BloodType? bloodType,
    String? healthInsurance,
    String? membershipNumber,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? notes,
    DateTime? updatedAt,
  }) {
    return MedicalProfile(
      fullName: fullName ?? this.fullName,
      documentNumber: documentNumber ?? this.documentNumber,
      birthDate: birthDate ?? this.birthDate,
      bloodType: bloodType ?? this.bloodType,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      membershipNumber: membershipNumber ?? this.membershipNumber,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'documentNumber': documentNumber,
      'birthDate': birthDate?.toIso8601String(),
      'bloodType': bloodType.name,
      'healthInsurance': healthInsurance,
      'membershipNumber': membershipNumber,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    return MedicalProfile(
      fullName: map['fullName'] as String? ?? '',
      documentNumber: map['documentNumber'] as String? ?? '',
      birthDate: _parseDate(map['birthDate']),
      bloodType: bloodTypeFromName(map['bloodType'] as String?),
      healthInsurance: map['healthInsurance'] as String? ?? '',
      membershipNumber: map['membershipNumber'] as String? ?? '',
      emergencyContactName: map['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory MedicalProfile.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El contenido del perfil médico no es válido.',
      );
    }

    return MedicalProfile.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
