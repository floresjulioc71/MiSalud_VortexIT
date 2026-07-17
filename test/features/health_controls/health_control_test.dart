import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/health_controls/models/health_control.dart';

void main() {
  test('HealthControl conserva sus datos al serializar', () {
    final HealthControl original = HealthControl(
      id: '1',
      recordedAt: DateTime(2026, 7, 17, 10, 30),
      systolicPressure: 120,
      diastolicPressure: 80,
      heartRate: 72,
      oxygenSaturation: 98,
      temperature: 36.6,
      weight: 86.4,
      bloodGlucose: 92,
      notes: 'Control matutino',
    );

    final HealthControl restored = HealthControl.fromJsonString(
      original.toJsonString(),
    );

    expect(restored.id, original.id);
    expect(restored.recordedAt, original.recordedAt);
    expect(restored.systolicPressure, 120);
    expect(restored.bloodGlucose, 92);
    expect(restored.notes, 'Control matutino');
  });

  test('HealthControl detecta mediciones cargadas', () {
    final HealthControl item = HealthControl(
      id: '2',
      recordedAt: DateTime(2026, 7, 17),
      weight: 80,
    );

    expect(item.hasMeasurements, isTrue);
  });
}
