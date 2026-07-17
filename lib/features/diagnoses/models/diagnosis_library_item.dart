import 'dart:convert';

class DiagnosisLibraryItem {
  final String id;
  final String description;
  final String normalizedDescription;
  final int useCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiagnosisLibraryItem({
    required this.id,
    required this.description,
    required this.normalizedDescription,
    required this.useCount,
    required this.createdAt,
    required this.updatedAt,
  });

  DiagnosisLibraryItem copyWith({
    String? id,
    String? description,
    String? normalizedDescription,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiagnosisLibraryItem(
      id: id ?? this.id,
      description: description ?? this.description,
      normalizedDescription:
          normalizedDescription ?? this.normalizedDescription,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String toJson() {
    return jsonEncode(<String, dynamic>{
      'id': id,
      'description': description,
      'normalizedDescription': normalizedDescription,
      'useCount': useCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  factory DiagnosisLibraryItem.fromJson(String source) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(
      jsonDecode(source) as Map,
    );

    final String description = (json['description'] as String? ?? '').trim();

    return DiagnosisLibraryItem(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      description: description,
      normalizedDescription:
          json['normalizedDescription'] as String? ??
          DiagnosisLibraryItem.normalize(description),
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
