enum VaccineScheduleStatus { complete, pending, overdue, upcomingBooster }

extension VaccineScheduleStatusX on VaccineScheduleStatus {
  String get label {
    switch (this) {
      case VaccineScheduleStatus.complete:
        return 'Esquema completo';
      case VaccineScheduleStatus.pending:
        return 'Dosis pendiente';
      case VaccineScheduleStatus.overdue:
        return 'Refuerzo vencido';
      case VaccineScheduleStatus.upcomingBooster:
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
    required this.mimeType,
    required this.sizeBytes,
  });

  bool get isImage {
    final String lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  bool get isPdf => name.toLowerCase().endsWith('.pdf');

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'path': path,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
  };

  factory VaccineAttachment.fromJson(Map<String, dynamic> json) {
    return VaccineAttachment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class VaccineRecord {
  final String id;
  final String vaccineName;
  final String preventsDisease;
  final DateTime applicationDate;
  final int doseNumber;
  final int totalDoses;
  final String laboratory;
  final String lotNumber;
  final String vaccinationCenter;
  final String professional;
  final String notes;
  final DateTime? nextDoseDate;
  final List<VaccineAttachment> attachments;

  const VaccineRecord({
    required this.id,
    required this.vaccineName,
    required this.preventsDisease,
    required this.applicationDate,
    required this.doseNumber,
    required this.totalDoses,
    required this.laboratory,
    required this.lotNumber,
    required this.vaccinationCenter,
    required this.professional,
    required this.notes,
    required this.nextDoseDate,
    required this.attachments,
  });

  VaccineScheduleStatus statusAt(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    if (nextDoseDate != null) {
      final DateTime next = DateTime(
        nextDoseDate!.year,
        nextDoseDate!.month,
        nextDoseDate!.day,
      );
      if (next.isBefore(today)) {
        return VaccineScheduleStatus.overdue;
      }
      if (next.difference(today).inDays <= 30) {
        return VaccineScheduleStatus.upcomingBooster;
      }
      return VaccineScheduleStatus.pending;
    }
    if (totalDoses > 0 && doseNumber >= totalDoses) {
      return VaccineScheduleStatus.complete;
    }
    return VaccineScheduleStatus.pending;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'vaccineName': vaccineName,
    'preventsDisease': preventsDisease,
    'applicationDate': applicationDate.toIso8601String(),
    'doseNumber': doseNumber,
    'totalDoses': totalDoses,
    'laboratory': laboratory,
    'lotNumber': lotNumber,
    'vaccinationCenter': vaccinationCenter,
    'professional': professional,
    'notes': notes,
    'nextDoseDate': nextDoseDate?.toIso8601String(),
    'attachments': attachments
        .map((VaccineAttachment item) => item.toJson())
        .toList(),
  };

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    final Object? rawAttachments = json['attachments'];
    return VaccineRecord(
      id: json['id'] as String? ?? '',
      vaccineName: json['vaccineName'] as String? ?? '',
      preventsDisease: json['preventsDisease'] as String? ?? '',
      applicationDate:
          DateTime.tryParse(json['applicationDate'] as String? ?? '') ??
          DateTime.now(),
      doseNumber: (json['doseNumber'] as num?)?.toInt() ?? 1,
      totalDoses: (json['totalDoses'] as num?)?.toInt() ?? 1,
      laboratory: json['laboratory'] as String? ?? '',
      lotNumber: json['lotNumber'] as String? ?? '',
      vaccinationCenter: json['vaccinationCenter'] as String? ?? '',
      professional: json['professional'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      nextDoseDate: DateTime.tryParse(json['nextDoseDate'] as String? ?? ''),
      attachments: rawAttachments is List
          ? rawAttachments
                .whereType<Map>()
                .map(
                  (Map item) => VaccineAttachment.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <VaccineAttachment>[],
    );
  }
}
