enum BloodType {
  unknown,
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
}

extension BloodTypeExtension on BloodType {
  String get label {
    switch (this) {
      case BloodType.unknown:
        return 'No especificado';
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
    }
  }
}

BloodType bloodTypeFromName(String? value) {
  if (value == null || value.isEmpty) {
    return BloodType.unknown;
  }

  return BloodType.values.firstWhere(
    (BloodType bloodType) => bloodType.name == value,
    orElse: () => BloodType.unknown,
  );
}
