import 'dart:convert';

class VaccineItem {
  final String id;
  final String name;
  final String dose;
  final DateTime? applicationDate;
  final String lotNumber;
  final String applicationPlace;
  final String professional;
  final DateTime? nextDoseDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaccineItem({
    required this.id,
    required this.name,
    this.dose = '',
    this.applicationDate,
    this.lotNumber = '',
    this.applicationPlace = '',
    this.professional = '',
    this.nextDoseDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'dose': dose,
      'applicationDate': applicationDate?.toIso8601String(),
      'lotNumber': lotNumber,
      'applicationPlace': applicationPlace,
      'professional': professional,
      'nextDoseDate': nextDoseDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaccineItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return VaccineItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      applicationDate: _parseDate(map['applicationDate']),
      lotNumber: map['lotNumber'] as String? ?? '',
      applicationPlace: map['applicationPlace'] as String? ?? '',
      professional: map['professional'] as String? ?? '',
      nextDoseDate: _parseDate(map['nextDoseDate']),
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory VaccineItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Vacuna inválida.');
    }

    return VaccineItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
