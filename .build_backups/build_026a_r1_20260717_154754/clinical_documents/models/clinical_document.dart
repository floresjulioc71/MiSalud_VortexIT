import 'dart:convert';

enum ClinicalDocumentType {
  prescription,
  medicalOrder,
  certificate,
  hospitalDischarge,
  informedConsent,
  insurance,
  disabilityCertificate,
  vaccinationCard,
  other,
}

extension ClinicalDocumentTypeX on ClinicalDocumentType {
  String get label {
    switch (this) {
      case ClinicalDocumentType.prescription:
        return 'Receta médica';
      case ClinicalDocumentType.medicalOrder:
        return 'Orden médica';
      case ClinicalDocumentType.certificate:
        return 'Certificado';
      case ClinicalDocumentType.hospitalDischarge:
        return 'Alta hospitalaria';
      case ClinicalDocumentType.informedConsent:
        return 'Consentimiento informado';
      case ClinicalDocumentType.insurance:
        return 'Obra social';
      case ClinicalDocumentType.disabilityCertificate:
        return 'Certificado de discapacidad';
      case ClinicalDocumentType.vaccinationCard:
        return 'Carnet de vacunación';
      case ClinicalDocumentType.other:
        return 'Otro';
    }
  }
}

class ClinicalDocument {
  final String id;
  final String title;
  final ClinicalDocumentType type;
  final DateTime documentDate;
  final String professional;
  final String institution;
  final String notes;
  final String fileName;
  final String filePath;
  final String mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClinicalDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.documentDate,
    this.professional = '',
    this.institution = '',
    this.notes = '',
    this.fileName = '',
    this.filePath = '',
    this.mimeType = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasFile => filePath.trim().isNotEmpty;
  bool get isPdf =>
      mimeType.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');
  bool get isImage =>
      mimeType.toLowerCase().startsWith('image/') ||
      <String>[
        '.jpg',
        '.jpeg',
        '.png',
        '.webp',
      ].any((String e) => fileName.toLowerCase().endsWith(e));

  ClinicalDocument copyWith({
    String? id,
    String? title,
    ClinicalDocumentType? type,
    DateTime? documentDate,
    String? professional,
    String? institution,
    String? notes,
    String? fileName,
    String? filePath,
    String? mimeType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      documentDate: documentDate ?? this.documentDate,
      professional: professional ?? this.professional,
      institution: institution ?? this.institution,
      notes: notes ?? this.notes,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'title': title,
    'type': type.name,
    'documentDate': documentDate.toIso8601String(),
    'professional': professional,
    'institution': institution,
    'notes': notes,
    'fileName': fileName,
    'filePath': filePath,
    'mimeType': mimeType,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory ClinicalDocument.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return ClinicalDocument(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      title: map['title'] as String? ?? '',
      type: ClinicalDocumentType.values.firstWhere(
        (v) => v.name == map['type'],
        orElse: () => ClinicalDocumentType.other,
      ),
      documentDate: _parseDate(map['documentDate']) ?? now,
      professional: map['professional'] as String? ?? '',
      institution: map['institution'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }
  String toJson() => jsonEncode(toMap());
  factory ClinicalDocument.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('Documento clínico inválido.');
    return ClinicalDocument.fromMap(decoded);
  }
  static DateTime? _parseDate(dynamic value) =>
      value is String && value.trim().isNotEmpty
      ? DateTime.tryParse(value)
      : null;
}
