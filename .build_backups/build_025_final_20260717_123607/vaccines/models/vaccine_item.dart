import 'dart:convert';

enum VaccineStatus { complete, pending, overdue, upcoming }

extension VaccineStatusX on VaccineStatus {
  String get label {
    switch (this) {
      case VaccineStatus.complete:
        return 'Esquema completo';
      case VaccineStatus.pending:
        return 'Dosis pendiente';
      case VaccineStatus.overdue:
        return 'Refuerzo vencido';
      case VaccineStatus.upcoming:
        return 'Próximo refuerzo';
    }
  }
}

class VaccineAttachment {
  final String id;
  final String name;
  final String path;
  final String mimeType;
  final int sizeBytes;

  const VaccineAttachment({
    required this.id,
    required this.name,
    required this.path,
    this.mimeType = '',
    this.sizeBytes = 0,
  });

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  bool get isImage {
    final String lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'path': path,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };
  }

  factory VaccineAttachment.fromMap(Map<String, dynamic> map) {
    return VaccineAttachment(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      path: map['path'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class VaccineItem {
  final String id;
  final String name;
  final String disease;
  final String dose;
  final int doseNumber;
  final int totalDoses;
  final DateTime? applicationDate;
  final String laboratory;
  final String lotNumber;
  final String applicationPlace;
  final String professional;
  final DateTime? nextDoseDate;
  final String notes;
  final List<VaccineAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaccineItem({
    required this.id,
    required this.name,
    this.disease = '',
    this.dose = '',
    this.doseNumber = 1,
    this.totalDoses = 1,
    this.applicationDate,
    this.laboratory = '',
    this.lotNumber = '',
    this.applicationPlace = '',
    this.professional = '',
    this.nextDoseDate,
    this.notes = '',
    this.attachments = const <VaccineAttachment>[],
    required this.createdAt,
    required this.updatedAt,
  });

  VaccineStatus statusAt(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (nextDoseDate != null) {
      final DateTime next = DateTime(
        nextDoseDate!.year,
        nextDoseDate!.month,
        nextDoseDate!.day,
      );

      if (next.isBefore(today)) {
        return VaccineStatus.overdue;
      }

      if (next.difference(today).inDays <= 30) {
        return VaccineStatus.upcoming;
      }

      return VaccineStatus.pending;
    }

    if (totalDoses > 0 && doseNumber >= totalDoses) {
      return VaccineStatus.complete;
    }

    return VaccineStatus.pending;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'disease': disease,
      'dose': dose,
      'doseNumber': doseNumber,
      'totalDoses': totalDoses,
      'applicationDate': applicationDate?.toIso8601String(),
      'laboratory': laboratory,
      'lotNumber': lotNumber,
      'applicationPlace': applicationPlace,
      'professional': professional,
      'nextDoseDate': nextDoseDate?.toIso8601String(),
      'notes': notes,
      'attachments': attachments
          .map((VaccineAttachment item) => item.toMap())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VaccineItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();
    final Object? rawAttachments = map['attachments'];

    return VaccineItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      disease: map['disease'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      doseNumber: (map['doseNumber'] as num?)?.toInt() ?? 1,
      totalDoses: (map['totalDoses'] as num?)?.toInt() ?? 1,
      applicationDate: _parseDate(map['applicationDate']),
      laboratory: map['laboratory'] as String? ?? '',
      lotNumber: map['lotNumber'] as String? ?? '',
      applicationPlace: map['applicationPlace'] as String? ?? '',
      professional: map['professional'] as String? ?? '',
      nextDoseDate: _parseDate(map['nextDoseDate']),
      notes: map['notes'] as String? ?? '',
      attachments: rawAttachments is List
          ? rawAttachments
                .whereType<Map>()
                .map(
                  (Map item) => VaccineAttachment.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const <VaccineAttachment>[],
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
