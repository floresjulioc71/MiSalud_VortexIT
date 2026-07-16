import 'dart:convert';

class SurgeryItem {
  final String id;
  final String procedure;
  final DateTime? surgeryDate;
  final String hospital;
  final String surgeon;
  final String reason;
  final String complications;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SurgeryItem({
    required this.id,
    required this.procedure,
    this.surgeryDate,
    this.hospital = '',
    this.surgeon = '',
    this.reason = '',
    this.complications = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'procedure': procedure,
      'surgeryDate': surgeryDate?.toIso8601String(),
      'hospital': hospital,
      'surgeon': surgeon,
      'reason': reason,
      'complications': complications,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SurgeryItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return SurgeryItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      procedure: map['procedure'] as String? ?? '',
      surgeryDate: _parseDate(map['surgeryDate']),
      hospital: map['hospital'] as String? ?? '',
      surgeon: map['surgeon'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      complications: map['complications'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SurgeryItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Cirugía inválida.');
    }

    return SurgeryItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
