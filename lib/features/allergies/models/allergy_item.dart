import 'dart:convert';

enum AllergyType { medication, food, substance, insect, material, other }

extension AllergyTypeExtension on AllergyType {
  String get label {
    switch (this) {
      case AllergyType.medication:
        return 'Medicamento';
      case AllergyType.food:
        return 'Alimento';
      case AllergyType.substance:
        return 'Sustancia';
      case AllergyType.insect:
        return 'Picadura';
      case AllergyType.material:
        return 'Material';
      case AllergyType.other:
        return 'Otro';
    }
  }
}

AllergyType allergyTypeFromName(String? value) {
  return AllergyType.values.firstWhere(
    (AllergyType type) => type.name == value,
    orElse: () => AllergyType.other,
  );
}

enum AllergySeverity { mild, moderate, severe }

extension AllergySeverityExtension on AllergySeverity {
  String get label {
    switch (this) {
      case AllergySeverity.mild:
        return 'Leve';
      case AllergySeverity.moderate:
        return 'Moderada';
      case AllergySeverity.severe:
        return 'Severa';
    }
  }
}

AllergySeverity allergySeverityFromName(String? value) {
  return AllergySeverity.values.firstWhere(
    (AllergySeverity severity) => severity.name == value,
    orElse: () => AllergySeverity.mild,
  );
}

class AllergyItem {
  final String id;
  final String allergen;
  final AllergyType type;
  final AllergySeverity severity;
  final String reaction;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AllergyItem({
    required this.id,
    required this.allergen,
    required this.type,
    required this.severity,
    this.reaction = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'allergen': allergen,
      'type': type.name,
      'severity': severity.name,
      'reaction': reaction,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AllergyItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return AllergyItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      allergen: map['allergen'] as String? ?? '',
      type: allergyTypeFromName(map['type'] as String?),
      severity: allergySeverityFromName(map['severity'] as String?),
      reaction: map['reaction'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AllergyItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Alergia inválida.');
    }

    return AllergyItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
