import 'package:flutter/material.dart';

import '../models/health_control.dart';

enum HealthMetric {
  weight,
  systolicPressure,
  diastolicPressure,
  bloodGlucose,
  heartRate,
  oxygenSaturation,
  temperature,
}

extension HealthMetricData on HealthMetric {
  String get label {
    switch (this) {
      case HealthMetric.weight:
        return 'Peso';
      case HealthMetric.systolicPressure:
        return 'Presión sistólica';
      case HealthMetric.diastolicPressure:
        return 'Presión diastólica';
      case HealthMetric.bloodGlucose:
        return 'Glucemia';
      case HealthMetric.heartRate:
        return 'Frecuencia cardíaca';
      case HealthMetric.oxygenSaturation:
        return 'Saturación de oxígeno';
      case HealthMetric.temperature:
        return 'Temperatura';
    }
  }

  String get unit {
    switch (this) {
      case HealthMetric.weight:
        return 'kg';
      case HealthMetric.systolicPressure:
      case HealthMetric.diastolicPressure:
        return 'mmHg';
      case HealthMetric.bloodGlucose:
        return 'mg/dL';
      case HealthMetric.heartRate:
        return 'lpm';
      case HealthMetric.oxygenSaturation:
        return '%';
      case HealthMetric.temperature:
        return '°C';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthMetric.weight:
        return Icons.monitor_weight_outlined;
      case HealthMetric.systolicPressure:
      case HealthMetric.diastolicPressure:
        return Icons.monitor_heart_outlined;
      case HealthMetric.bloodGlucose:
        return Icons.water_drop_outlined;
      case HealthMetric.heartRate:
        return Icons.favorite_outline;
      case HealthMetric.oxygenSaturation:
        return Icons.air;
      case HealthMetric.temperature:
        return Icons.thermostat_outlined;
    }
  }

  Color color(ColorScheme scheme) {
    switch (this) {
      case HealthMetric.weight:
        return scheme.primary;
      case HealthMetric.systolicPressure:
        return Colors.red.shade700;
      case HealthMetric.diastolicPressure:
        return Colors.deepOrange.shade700;
      case HealthMetric.bloodGlucose:
        return Colors.orange.shade800;
      case HealthMetric.heartRate:
        return Colors.pink.shade600;
      case HealthMetric.oxygenSaturation:
        return Colors.green.shade700;
      case HealthMetric.temperature:
        return Colors.purple.shade600;
    }
  }

  double? valueOf(HealthControl item) {
    switch (this) {
      case HealthMetric.weight:
        return item.weight;
      case HealthMetric.systolicPressure:
        return item.systolicPressure?.toDouble();
      case HealthMetric.diastolicPressure:
        return item.diastolicPressure?.toDouble();
      case HealthMetric.bloodGlucose:
        return item.bloodGlucose;
      case HealthMetric.heartRate:
        return item.heartRate?.toDouble();
      case HealthMetric.oxygenSaturation:
        return item.oxygenSaturation?.toDouble();
      case HealthMetric.temperature:
        return item.temperature;
    }
  }

  int get decimals {
    switch (this) {
      case HealthMetric.weight:
      case HealthMetric.temperature:
        return 1;
      case HealthMetric.systolicPressure:
      case HealthMetric.diastolicPressure:
      case HealthMetric.bloodGlucose:
      case HealthMetric.heartRate:
      case HealthMetric.oxygenSaturation:
        return 0;
    }
  }
}

class HealthMetricPoint {
  final DateTime date;
  final double value;

  const HealthMetricPoint({required this.date, required this.value});
}

class HealthMetricStatistics {
  final double minimum;
  final double maximum;
  final double average;
  final double latest;
  final int count;

  const HealthMetricStatistics({
    required this.minimum,
    required this.maximum,
    required this.average,
    required this.latest,
    required this.count,
  });

  factory HealthMetricStatistics.fromPoints(List<HealthMetricPoint> points) {
    if (points.isEmpty) {
      throw ArgumentError('Se requiere al menos un punto.');
    }

    double minimum = points.first.value;
    double maximum = points.first.value;
    double sum = 0;

    for (final HealthMetricPoint point in points) {
      if (point.value < minimum) {
        minimum = point.value;
      }
      if (point.value > maximum) {
        maximum = point.value;
      }
      sum += point.value;
    }

    return HealthMetricStatistics(
      minimum: minimum,
      maximum: maximum,
      average: sum / points.length,
      latest: points.last.value,
      count: points.length,
    );
  }
}
