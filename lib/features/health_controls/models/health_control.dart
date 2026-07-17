import 'dart:convert';

class HealthControl {
  final String id;
  final DateTime recordedAt;
  final int? systolicPressure;
  final int? diastolicPressure;
  final int? heartRate;
  final int? oxygenSaturation;
  final double? temperature;
  final double? weight;
  final double? bloodGlucose;
  final String notes;

  const HealthControl({
    required this.id,
    required this.recordedAt,
    this.systolicPressure,
    this.diastolicPressure,
    this.heartRate,
    this.oxygenSaturation,
    this.temperature,
    this.weight,
    this.bloodGlucose,
    this.notes = '',
  });

  HealthControl copyWith({
    String? id,
    DateTime? recordedAt,
    int? systolicPressure,
    int? diastolicPressure,
    int? heartRate,
    int? oxygenSaturation,
    double? temperature,
    double? weight,
    double? bloodGlucose,
    String? notes,
  }) {
    return HealthControl(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      systolicPressure: systolicPressure ?? this.systolicPressure,
      diastolicPressure: diastolicPressure ?? this.diastolicPressure,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'systolicPressure': systolicPressure,
    'diastolicPressure': diastolicPressure,
    'heartRate': heartRate,
    'oxygenSaturation': oxygenSaturation,
    'temperature': temperature,
    'weight': weight,
    'bloodGlucose': bloodGlucose,
    'notes': notes,
  };

  String toJsonString() => jsonEncode(toJson());

  factory HealthControl.fromJsonString(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Control de salud inválido.');
    }
    return HealthControl.fromJson(decoded);
  }

  factory HealthControl.fromJson(Map<String, dynamic> json) {
    return HealthControl(
      id: json['id'] as String? ?? '',
      recordedAt:
          DateTime.tryParse(json['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      systolicPressure: (json['systolicPressure'] as num?)?.toInt(),
      diastolicPressure: (json['diastolicPressure'] as num?)?.toInt(),
      heartRate: (json['heartRate'] as num?)?.toInt(),
      oxygenSaturation: (json['oxygenSaturation'] as num?)?.toInt(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bloodGlucose: (json['bloodGlucose'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
    );
  }

  bool get hasMeasurements =>
      systolicPressure != null ||
      diastolicPressure != null ||
      heartRate != null ||
      oxygenSaturation != null ||
      temperature != null ||
      weight != null ||
      bloodGlucose != null;
}
