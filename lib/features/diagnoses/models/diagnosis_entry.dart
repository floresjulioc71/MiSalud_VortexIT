import 'dart:convert';

enum DiagnosisSystem { icd11, icd10, snomedCt, icpc2, freeText }

extension DiagnosisSystemExtension on DiagnosisSystem {
  String get label {
    switch (this) {
      case DiagnosisSystem.icd11:
        return 'CIE-11';
      case DiagnosisSystem.icd10:
        return 'CIE-10';
      case DiagnosisSystem.snomedCt:
        return 'SNOMED CT';
      case DiagnosisSystem.icpc2:
        return 'ICPC-2';
      case DiagnosisSystem.freeText:
        return 'Texto libre';
    }
  }
}

DiagnosisSystem diagnosisSystemFromName(String? value) {
  return DiagnosisSystem.values.firstWhere(
    (DiagnosisSystem system) => system.name == value,
    orElse: () => DiagnosisSystem.freeText,
  );
}

enum DiagnosisStatus { active, chronic, resolved, suspected, ruledOut }

extension DiagnosisStatusExtension on DiagnosisStatus {
  String get label {
    switch (this) {
      case DiagnosisStatus.active:
        return 'Activo';
      case DiagnosisStatus.chronic:
        return 'Crónico';
      case DiagnosisStatus.resolved:
        return 'Resuelto';
      case DiagnosisStatus.suspected:
        return 'Sospecha';
      case DiagnosisStatus.ruledOut:
        return 'Descartado';
    }
  }
}

DiagnosisStatus diagnosisStatusFromName(String? value) {
  return DiagnosisStatus.values.firstWhere(
    (DiagnosisStatus status) => status.name == value,
    orElse: () => DiagnosisStatus.active,
  );
}

enum DiagnosisOrigin {
  doctorConfirmed,
  hospitalDischarge,
  studyResult,
  patientReported,
  selfRecord,
}

extension DiagnosisOriginExtension on DiagnosisOrigin {
  String get label {
    switch (this) {
      case DiagnosisOrigin.doctorConfirmed:
        return 'Confirmado por médico';
      case DiagnosisOrigin.hospitalDischarge:
        return 'Alta hospitalaria';
      case DiagnosisOrigin.studyResult:
        return 'Resultado de estudio';
      case DiagnosisOrigin.patientReported:
        return 'Informado por el paciente';
      case DiagnosisOrigin.selfRecord:
        return 'Autoregistro';
    }
  }
}

DiagnosisOrigin diagnosisOriginFromName(String? value) {
  return DiagnosisOrigin.values.firstWhere(
    (DiagnosisOrigin origin) => origin.name == value,
    orElse: () => DiagnosisOrigin.selfRecord,
  );
}

class DiagnosisEntry {
  final String id;
  final DiagnosisSystem primarySystem;
  final String primaryCode;
  final String description;
  final String icd10Code;
  final String snomedCtCode;
  final String icpc2Code;
  final String terminologyVersion;
  final DiagnosisStatus status;
  final DiagnosisOrigin origin;
  final DateTime? diagnosisDate;
  final String notes;

  const DiagnosisEntry({
    required this.id,
    required this.primarySystem,
    required this.primaryCode,
    required this.description,
    this.icd10Code = '',
    this.snomedCtCode = '',
    this.icpc2Code = '',
    this.terminologyVersion = '',
    this.status = DiagnosisStatus.active,
    this.origin = DiagnosisOrigin.selfRecord,
    this.diagnosisDate,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'primarySystem': primarySystem.name,
      'primaryCode': primaryCode,
      'description': description,
      'icd10Code': icd10Code,
      'snomedCtCode': snomedCtCode,
      'icpc2Code': icpc2Code,
      'terminologyVersion': terminologyVersion,
      'status': status.name,
      'origin': origin.name,
      'diagnosisDate': diagnosisDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory DiagnosisEntry.fromMap(Map<String, dynamic> map) {
    return DiagnosisEntry(
      id: map['id'] as String? ?? '',
      primarySystem: diagnosisSystemFromName(map['primarySystem'] as String?),
      primaryCode: map['primaryCode'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icd10Code: map['icd10Code'] as String? ?? '',
      snomedCtCode: map['snomedCtCode'] as String? ?? '',
      icpc2Code: map['icpc2Code'] as String? ?? '',
      terminologyVersion: map['terminologyVersion'] as String? ?? '',
      status: diagnosisStatusFromName(map['status'] as String?),
      origin: diagnosisOriginFromName(map['origin'] as String?),
      diagnosisDate: _parseDate(map['diagnosisDate']),
      notes: map['notes'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiagnosisEntry.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Diagnóstico inválido.');
    }

    return DiagnosisEntry.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
