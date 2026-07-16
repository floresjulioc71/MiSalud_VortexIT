import 'dart:convert';

enum StudyCategory {
  laboratory,
  radiography,
  resonance,
  tomography,
  ultrasound,
  electrocardiogram,
  echocardiogram,
  electroencephalogram,
  pathology,
  ophthalmology,
  audiometry,
  genetics,
  other,
}

extension StudyCategoryExtension on StudyCategory {
  String get label {
    switch (this) {
      case StudyCategory.laboratory:
        return 'Laboratorio';
      case StudyCategory.radiography:
        return 'Radiografía';
      case StudyCategory.resonance:
        return 'Resonancia';
      case StudyCategory.tomography:
        return 'Tomografía';
      case StudyCategory.ultrasound:
        return 'Ecografía';
      case StudyCategory.electrocardiogram:
        return 'Electrocardiograma';
      case StudyCategory.echocardiogram:
        return 'Ecocardiograma';
      case StudyCategory.electroencephalogram:
        return 'Electroencefalograma';
      case StudyCategory.pathology:
        return 'Anatomía patológica';
      case StudyCategory.ophthalmology:
        return 'Oftalmología';
      case StudyCategory.audiometry:
        return 'Audiometría';
      case StudyCategory.genetics:
        return 'Genética';
      case StudyCategory.other:
        return 'Otro';
    }
  }
}

StudyCategory studyCategoryFromName(String? value) {
  return StudyCategory.values.firstWhere(
    (StudyCategory category) => category.name == value,
    orElse: () => StudyCategory.other,
  );
}

enum StudyStatus { pending, completed }

extension StudyStatusExtension on StudyStatus {
  String get label {
    switch (this) {
      case StudyStatus.pending:
        return 'Pendiente';
      case StudyStatus.completed:
        return 'Realizado';
    }
  }
}

StudyStatus studyStatusFromName(String? value) {
  return StudyStatus.values.firstWhere(
    (StudyStatus status) => status.name == value,
    orElse: () => StudyStatus.completed,
  );
}

enum StudyAttachmentType { none, pdf, image }

extension StudyAttachmentTypeExtension on StudyAttachmentType {
  String get label {
    switch (this) {
      case StudyAttachmentType.none:
        return 'Sin archivo';
      case StudyAttachmentType.pdf:
        return 'PDF';
      case StudyAttachmentType.image:
        return 'Imagen';
    }
  }
}

StudyAttachmentType studyAttachmentTypeFromName(String? value) {
  return StudyAttachmentType.values.firstWhere(
    (StudyAttachmentType type) => type.name == value,
    orElse: () => StudyAttachmentType.none,
  );
}

class StudyItem {
  final String id;
  final String name;
  final StudyCategory category;
  final StudyStatus status;
  final DateTime? studyDate;
  final String requestingDoctor;
  final String institution;
  final String result;
  final String notes;
  final String? attachmentPath;
  final String? attachmentOriginalName;
  final StudyAttachmentType attachmentType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.studyDate,
    this.requestingDoctor = '',
    this.institution = '',
    this.result = '',
    this.notes = '',
    this.attachmentPath,
    this.attachmentOriginalName,
    this.attachmentType = StudyAttachmentType.none,
    required this.createdAt,
    required this.updatedAt,
  });

  StudyItem copyWith({
    String? id,
    String? name,
    StudyCategory? category,
    StudyStatus? status,
    DateTime? studyDate,
    bool clearStudyDate = false,
    String? requestingDoctor,
    String? institution,
    String? result,
    String? notes,
    String? attachmentPath,
    bool clearAttachmentPath = false,
    String? attachmentOriginalName,
    bool clearAttachmentOriginalName = false,
    StudyAttachmentType? attachmentType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      studyDate: clearStudyDate ? null : studyDate ?? this.studyDate,
      requestingDoctor: requestingDoctor ?? this.requestingDoctor,
      institution: institution ?? this.institution,
      result: result ?? this.result,
      notes: notes ?? this.notes,
      attachmentPath: clearAttachmentPath
          ? null
          : attachmentPath ?? this.attachmentPath,
      attachmentOriginalName: clearAttachmentOriginalName
          ? null
          : attachmentOriginalName ?? this.attachmentOriginalName,
      attachmentType: attachmentType ?? this.attachmentType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'category': category.name,
      'status': status.name,
      'studyDate': studyDate?.toIso8601String(),
      'requestingDoctor': requestingDoctor,
      'institution': institution,
      'result': result,
      'notes': notes,
      'attachmentPath': attachmentPath,
      'attachmentOriginalName': attachmentOriginalName,
      'attachmentType': attachmentType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return StudyItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      category: studyCategoryFromName(map['category'] as String?),
      status: studyStatusFromName(map['status'] as String?),
      studyDate: _parseDate(map['studyDate']),
      requestingDoctor: map['requestingDoctor'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      result: map['result'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      attachmentPath: map['attachmentPath'] as String?,
      attachmentOriginalName: map['attachmentOriginalName'] as String?,
      attachmentType: studyAttachmentTypeFromName(
        map['attachmentType'] as String?,
      ),
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory StudyItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Estudio médico inválido.');
    }

    return StudyItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
