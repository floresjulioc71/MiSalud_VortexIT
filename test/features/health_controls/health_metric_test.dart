import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/health_controls/widgets/health_metric.dart';

void main() {
  group('HealthMetricStatistics', () {
    test('calcula mínimo, máximo, promedio, último y cantidad', () {
      final List<HealthMetricPoint> points = <HealthMetricPoint>[
        HealthMetricPoint(date: DateTime(2026, 1, 1), value: 80),
        HealthMetricPoint(date: DateTime(2026, 1, 2), value: 82),
        HealthMetricPoint(date: DateTime(2026, 1, 3), value: 84),
      ];

      final HealthMetricStatistics statistics =
          HealthMetricStatistics.fromPoints(points);

      expect(statistics.minimum, 80);
      expect(statistics.maximum, 84);
      expect(statistics.average, 82);
      expect(statistics.latest, 84);
      expect(statistics.count, 3);
    });

    test('rechaza una lista vacía', () {
      expect(
        () => HealthMetricStatistics.fromPoints(<HealthMetricPoint>[]),
        throwsArgumentError,
      );
    });
  });
}
