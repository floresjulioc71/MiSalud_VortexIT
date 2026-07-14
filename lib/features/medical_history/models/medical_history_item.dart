import 'dart:convert';

enum MedicalHistoryStatus { active, controlled, resolved }

extension MedicalHistoryStatusExtension on MedicalHistoryStatus {
  String get label {
    switch (this) {
      case MedicalHistoryStatus.active:
        return 'Activo';
      case MedicalHistoryStatus.controlled:
        return 'Controlado';
      case MedicalHistoryStatus.resolved:
        return 'Resuelto';
    }
  }
}

MedicalHistoryStatus medicalHistoryStatusFromName(String? value) {
  return MedicalHistoryStatus.values.firstWhere(
    (MedicalHistoryStatus status) => status.name == value,
    orElse: () => MedicalHistoryStatus.active,
  );
}

class MedicalHistoryItem {
  final String id;
  final String title;
  final String description;
  final DateTime? diagnosisDate;
  final MedicalHistoryStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicalHistoryItem({
    required this.id,
    required this.title,
    this.description = '',
    this.diagnosisDate,
    this.status = MedicalHistoryStatus.active,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  MedicalHistoryItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? diagnosisDate,
    MedicalHistoryStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalHistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'diagnosisDate': diagnosisDate?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalHistoryItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return MedicalHistoryItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      diagnosisDate: _parseDate(map['diagnosisDate']),
      status: medicalHistoryStatusFromName(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicalHistoryItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Antecedente médico inválido.');
    }

    return MedicalHistoryItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
