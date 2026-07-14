import 'dart:convert';

enum MedicationStatus { active, paused, completed }

extension MedicationStatusExtension on MedicationStatus {
  String get label {
    switch (this) {
      case MedicationStatus.active:
        return 'Activo';
      case MedicationStatus.paused:
        return 'Suspendido';
      case MedicationStatus.completed:
        return 'Finalizado';
    }
  }
}

MedicationStatus medicationStatusFromName(String? value) {
  return MedicationStatus.values.firstWhere(
    (MedicationStatus status) => status.name == value,
    orElse: () => MedicationStatus.active,
  );
}

enum MedicationRoute {
  oral,
  sublingual,
  topical,
  inhaled,
  injectable,
  ophthalmic,
  otic,
  other,
}

extension MedicationRouteExtension on MedicationRoute {
  String get label {
    switch (this) {
      case MedicationRoute.oral:
        return 'Oral';
      case MedicationRoute.sublingual:
        return 'Sublingual';
      case MedicationRoute.topical:
        return 'Tópica';
      case MedicationRoute.inhaled:
        return 'Inhalatoria';
      case MedicationRoute.injectable:
        return 'Inyectable';
      case MedicationRoute.ophthalmic:
        return 'Oftálmica';
      case MedicationRoute.otic:
        return 'Ótica';
      case MedicationRoute.other:
        return 'Otra';
    }
  }
}

MedicationRoute medicationRouteFromName(String? value) {
  return MedicationRoute.values.firstWhere(
    (MedicationRoute route) => route.name == value,
    orElse: () => MedicationRoute.other,
  );
}

class MedicationItem {
  final String id;
  final String name;
  final String activeIngredient;
  final String dose;
  final String frequency;
  final String schedule;
  final MedicationRoute route;
  final DateTime? startDate;
  final DateTime? endDate;
  final MedicationStatus status;
  final String prescribedBy;
  final String instructions;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationItem({
    required this.id,
    required this.name,
    this.activeIngredient = '',
    this.dose = '',
    this.frequency = '',
    this.schedule = '',
    this.route = MedicationRoute.oral,
    this.startDate,
    this.endDate,
    this.status = MedicationStatus.active,
    this.prescribedBy = '',
    this.instructions = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'activeIngredient': activeIngredient,
      'dose': dose,
      'frequency': frequency,
      'schedule': schedule,
      'route': route.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.name,
      'prescribedBy': prescribedBy,
      'instructions': instructions,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicationItem.fromMap(Map<String, dynamic> map) {
    final DateTime now = DateTime.now();

    return MedicationItem(
      id: map['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      activeIngredient: map['activeIngredient'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      schedule: map['schedule'] as String? ?? '',
      route: medicationRouteFromName(map['route'] as String?),
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      status: medicationStatusFromName(map['status'] as String?),
      prescribedBy: map['prescribedBy'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']) ?? now,
      updatedAt: _parseDate(map['updatedAt']) ?? now,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MedicationItem.fromJson(String source) {
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Medicamento inválido.');
    }

    return MedicationItem.fromMap(decoded);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}
