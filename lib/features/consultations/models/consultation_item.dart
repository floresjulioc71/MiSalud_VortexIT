import 'dart:convert';

import '../../diagnoses/models/diagnosis_entry.dart';

class ConsultationItem {
  final String id;
  final DateTime consultationDateTime;
  final String doctorId;
  final String doctorNameSnapshot;
  final String specialtySnapshot;
  final String reason;
  final List<DiagnosisEntry> diagnoses;
  final String treatment;
  final String prescribedMedication;
  final String requestedStudies;
  final DateTime? nextControlDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsultationItem({
    required this.id,
    required this.consultationDateTime,
    this.doctorId = '',
    this.doctorNameSnapshot = '',
    this.specialtySnapshot = '',
    this.reason = '',
    this.diagnoses = const <DiagnosisEntry>[],
    this.treatment = '',
    this.prescribedMedication = '',
    this.requestedStudies = '',
    this.nextControlDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'consultationDateTime': consultationDateTime.toIso8601String(),
      'doctorId': doctorId,
      'doctorNameSnapshot': doctorNameSnapshot,
      'specialtySnapshot': specialtySnapshot,
      'reason': reason,
      'diagnoses': diagnoses
          .map((DiagnosisEntry diagnosis) => diagnosis.toMap())
          .toList(),
      'treatment': treatment,
      'prescribedMedication': prescribedMedication,
      'requestedStudies': requestedStudies,
      'nextControlDate': nextControlDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ConsultationItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();
    final dynamic rawDiagnoses = map['diagnoses'];

    return ConsultationItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      consultationDateTime: _parseDate(map['consultationDateTime']) ?? now,
      doctorId: map['doctorId'] as String? ?? '',
      doctorNameSnapshot: map['doctorNameSnapshot'] as String? ?? '',
      specialtySnapshot: map['specialtySnapshot'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      diagnoses: rawDiagnoses is List<dynamic>
          ? rawDiagnoses
                .whereType<Map<String, dynamic>>()
                .map(DiagnosisEntry.fromMap)
                .toList()
          : <DiagnosisEntry>[],
      treatment: map['treatment'] as String? ?? '',
      prescribedMedication: map['prescribedMedication'] as String? ?? '',
      requestedStudies: map['requestedStudies'] as String? ?? '',
      nextControlDate: _parseDate(map['nextControlDate']),
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ConsultationItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Consulta médica inválida.');
    }

    return ConsultationItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
