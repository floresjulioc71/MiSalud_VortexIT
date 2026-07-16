import 'dart:convert';

class FamilyMember {
  final String id;
  final String name;
  final String relationship;
  final DateTime? birthDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.birthDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'name': name,
    'relationship': relationship,
    'birthDate': birthDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();
    DateTime? parse(dynamic value) =>
        value is String ? DateTime.tryParse(value) : null;

    return FamilyMember(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      birthDate: parse(map['birthDate']),
      createdAt: parse(map['createdAt']) ?? now,
      updatedAt: parse(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FamilyMember.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Integrante familiar inválido.');
    }
    return FamilyMember.fromMap(decoded);
  }
}
