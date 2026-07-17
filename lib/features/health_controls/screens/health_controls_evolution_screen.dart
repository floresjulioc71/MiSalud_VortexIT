import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/health_control.dart';
import '../services/health_control_storage_service.dart';
import '../widgets/health_metric.dart';

class HealthControlsEvolutionScreen extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;

  const HealthControlsEvolutionScreen({
    super.key,
    this.initialDateFrom,
    this.initialDateTo,
  });

  @override
  State<HealthControlsEvolutionScreen> createState() =>
      _HealthControlsEvolutionScreenState();
}

class _HealthControlsEvolutionScreenState
    extends State<HealthControlsEvolutionScreen> {
  List<HealthControl> _items = <HealthControl>[];
  HealthMetric _metric = HealthMetric.weight;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    _items = HealthControlStorageService.loadItems();
  }

  List<HealthControl> get _visibleItems {
    final List<HealthControl> result = _items.where((HealthControl item) {
      final DateTime day = DateTime(
        item.recordedAt.year,
        item.recordedAt.month,
        item.recordedAt.day,
      );
      if (_dateFrom != null && day.isBefore(_dateFrom!)) {
        return false;
      }
      if (_dateTo != null && day.isAfter(_dateTo!)) {
        return false;
      }
      return true;
    }).toList();

    result.sort(
      (HealthControl a, HealthControl b) =>
          a.recordedAt.compareTo(b.recordedAt),
    );
    return result;
  }

  List<HealthMetricPoint> get _points {
    final List<HealthMetricPoint> points = <HealthMetricPoint>[];
    for (final HealthControl item in _visibleItems) {
      final double? value = _metric.valueOf(item);
      if (value != null) {
        points.add(HealthMetricPoint(date: item.recordedAt, value: value));
      }
    }
    return points;
  }

  void _setQuickRange(int? days) {
    setState(() {
      if (days == null) {
        _dateFrom = null;
        _dateTo = null;
        return;
      }

      final DateTime now = DateTime.now();
      _dateTo = DateTime(now.year, now.month, now.day);
      _dateFrom = _dateTo!.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _selectCustomRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );

    if (range == null || !mounted) {
      return;
    }

    setState(() {
      _dateFrom = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _dateTo = DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<HealthMetricPoint> points = _points;
    final HealthMetricStatistics? statistics = points.isEmpty
        ? null
        : HealthMetricStatistics.fromPoints(points);

    return Scaffold(
      appBar: AppBar(title: const Text('Evolución de controles')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          _MetricSelector(
            value: _metric,
            onChanged: (HealthMetric metric) {
              setState(() => _metric = metric);
            },
          ),
          const SizedBox(height: 12),
          _EvolutionFilterBar(
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            onAll: () => _setQuickRange(null),
            on30: () => _setQuickRange(30),
            on90: () => _setQuickRange(90),
            onYear: () => _setQuickRange(365),
            onCustom: _selectCustomRange,
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            _NoMeasurements(metric: _metric)
          else ...<Widget>[
            _EvolutionChart(metric: _metric, points: points),
            const SizedBox(height: 16),
            _StatisticsPanel(metric: _metric, statistics: statistics!),
          ],
        ],
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  final HealthMetric value;
  final ValueChanged<HealthMetric> onChanged;

  const _MetricSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<HealthMetric>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Indicador',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.insights_outlined),
      ),
      items: HealthMetric.values
          .map(
            (HealthMetric metric) => DropdownMenuItem<HealthMetric>(
              value: metric,
              child: Row(
                children: <Widget>[
                  Icon(metric.icon, size: 20),
                  const SizedBox(width: 10),
                  Text(metric.label),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (HealthMetric? metric) {
        if (metric != null) {
          onChanged(metric);
        }
      },
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  final HealthMetric metric;
  final List<HealthMetricPoint> points;

  const _EvolutionChart({required this.metric, required this.points});

  @override
  Widget build(BuildContext context) {
    final Color color = metric.color(Theme.of(context).colorScheme);
    final List<FlSpot> spots = <FlSpot>[
      for (int index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].value),
    ];

    double minimum = points.first.value;
    double maximum = points.first.value;
    for (final HealthMetricPoint point in points) {
      minimum = math.min(minimum, point.value);
      maximum = math.max(maximum, point.value);
    }

    final double rawRange = maximum - minimum;
    final double padding = rawRange == 0
        ? math.max(maximum.abs() * 0.08, 1)
        : rawRange * 0.18;
    final double minY = minimum - padding;
    final double maxY = maximum + padding;
    final double interval = _interval(minY, maxY);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(metric.icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${metric.label} (${metric.unit})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 320,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: math.max(points.length - 1, 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Theme.of(context).dividerColor),
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: interval,
                        getTitlesWidget: (double value, TitleMeta meta) => Text(
                          value.toStringAsFixed(metric.decimals),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: _xInterval(points.length),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.round();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _shortDate(points[index].date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          final int index = spot.x.round();
                          return LineTooltipItem(
                            '${_dateTime(points[index].date)}\n'
                            '${spot.y.toStringAsFixed(metric.decimals)} ${metric.unit}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: spots,
                      isCurved: points.length > 2,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: points.length <= 40),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 350),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _interval(double minimum, double maximum) {
    final double range = maximum - minimum;
    if (range <= 5) {
      return 1;
    }
    if (range <= 20) {
      return 5;
    }
    if (range <= 60) {
      return 10;
    }
    if (range <= 150) {
      return 25;
    }
    return 50;
  }

  static double _xInterval(int count) {
    if (count <= 6) {
      return 1;
    }
    return math.max(1, (count / 5).ceil()).toDouble();
  }

  static String _shortDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static String _dateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _StatisticsPanel extends StatelessWidget {
  final HealthMetric metric;
  final HealthMetricStatistics statistics;

  const _StatisticsPanel({required this.metric, required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumen estadístico',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 760
                    ? 5
                    : constraints.maxWidth >= 430
                    ? 3
                    : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  childAspectRatio: 1.55,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: <Widget>[
                    _StatisticTile(
                      label: 'Mínimo',
                      value: _format(statistics.minimum),
                    ),
                    _StatisticTile(
                      label: 'Máximo',
                      value: _format(statistics.maximum),
                    ),
                    _StatisticTile(
                      label: 'Promedio',
                      value: _format(statistics.average),
                    ),
                    _StatisticTile(
                      label: 'Último',
                      value: _format(statistics.latest),
                    ),
                    _StatisticTile(
                      label: 'Mediciones',
                      value: statistics.count.toString(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _format(double value) =>
      '${value.toStringAsFixed(metric.decimals)} ${metric.unit}';
}

class _StatisticTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionFilterBar extends StatelessWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final VoidCallback onAll;
  final VoidCallback on30;
  final VoidCallback on90;
  final VoidCallback onYear;
  final VoidCallback onCustom;

  const _EvolutionFilterBar({
    required this.dateFrom,
    required this.dateTo,
    required this.onAll,
    required this.on30,
    required this.on90,
    required this.onYear,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  ActionChip(label: const Text('Todos'), onPressed: onAll),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('30 días'), onPressed: on30),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('90 días'), onPressed: on90),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('1 año'), onPressed: onYear),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_outlined, size: 18),
                    label: const Text('Rango'),
                    onPressed: onCustom,
                  ),
                ],
              ),
            ),
            if (dateFrom != null || dateTo != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Período: ${dateFrom == null ? 'inicio' : _date(dateFrom!)} al '
                '${dateTo == null ? 'hoy' : _date(dateTo!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _NoMeasurements extends StatelessWidget {
  final HealthMetric metric;

  const _NoMeasurements({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: <Widget>[
            Icon(metric.icon, size: 64),
            const SizedBox(height: 16),
            Text(
              'No existen mediciones de ${metric.label.toLowerCase()} '
              'para el período seleccionado.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
