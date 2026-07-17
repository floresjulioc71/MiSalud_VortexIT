enum MedicalStudyStatus { pending, completed, reported }

extension MedicalStudyStatusX on MedicalStudyStatus {
  String get label {
    switch (this) {
      case MedicalStudyStatus.pending:
        return 'Pendiente';
      case MedicalStudyStatus.completed:
        return 'Realizado';
      case MedicalStudyStatus.reported:
        return 'Informado';
    }
  }

  static MedicalStudyStatus fromName(String? value) {
    return MedicalStudyStatus.values.firstWhere(
      (MedicalStudyStatus item) => item.name == value,
      orElse: () => MedicalStudyStatus.pending,
    );
  }
}

class MedicalStudyAttachment {
  final String id;
  final String name;
  final String path;
  final String mimeType;
  final int sizeBytes;

  const MedicalStudyAttachment({
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

  factory MedicalStudyAttachment.fromJson(Map<String, dynamic> json) {
    return MedicalStudyAttachment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      path: json['path'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class MedicalStudy {
  final String id;
  final DateTime studyDate;
  final String type;
  final String name;
  final String medicalCenter;
  final String professional;
  final MedicalStudyStatus status;
  final String result;
  final String notes;
  final DateTime? nextCheckDate;
  final List<MedicalStudyAttachment> attachments;

  const MedicalStudy({
    required this.id,
    required this.studyDate,
    required this.type,
    required this.name,
    required this.medicalCenter,
    required this.professional,
    required this.status,
    required this.result,
    required this.notes,
    required this.nextCheckDate,
    required this.attachments,
  });

  MedicalStudy copyWith({
    String? id,
    DateTime? studyDate,
    String? type,
    String? name,
    String? medicalCenter,
    String? professional,
    MedicalStudyStatus? status,
    String? result,
    String? notes,
    DateTime? nextCheckDate,
    bool clearNextCheckDate = false,
    List<MedicalStudyAttachment>? attachments,
  }) {
    return MedicalStudy(
      id: id ?? this.id,
      studyDate: studyDate ?? this.studyDate,
      type: type ?? this.type,
      name: name ?? this.name,
      medicalCenter: medicalCenter ?? this.medicalCenter,
      professional: professional ?? this.professional,
      status: status ?? this.status,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      nextCheckDate: clearNextCheckDate
          ? null
          : nextCheckDate ?? this.nextCheckDate,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studyDate': studyDate.toIso8601String(),
    'type': type,
    'name': name,
    'medicalCenter': medicalCenter,
    'professional': professional,
    'status': status.name,
    'result': result,
    'notes': notes,
    'nextCheckDate': nextCheckDate?.toIso8601String(),
    'attachments': attachments
        .map((MedicalStudyAttachment item) => item.toJson())
        .toList(),
  };

  factory MedicalStudy.fromJson(Map<String, dynamic> json) {
    final Object? rawAttachments = json['attachments'];
    return MedicalStudy(
      id: json['id'] as String? ?? '',
      studyDate:
          DateTime.tryParse(json['studyDate'] as String? ?? '') ??
          DateTime.now(),
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      medicalCenter: json['medicalCenter'] as String? ?? '',
      professional: json['professional'] as String? ?? '',
      status: MedicalStudyStatusX.fromName(json['status'] as String?),
      result: json['result'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      nextCheckDate: DateTime.tryParse(json['nextCheckDate'] as String? ?? ''),
      attachments: rawAttachments is List
          ? rawAttachments
                .whereType<Map>()
                .map(
                  (Map item) => MedicalStudyAttachment.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <MedicalStudyAttachment>[],
    );
  }
}
