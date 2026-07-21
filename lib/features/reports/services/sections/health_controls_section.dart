import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class HealthControlsSection {
  const HealthControlsSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.healthControls.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Controles de Salud'),
    ];

    for (final Map<String, dynamic> item in report.healthControls) {
      final String systolic = ReportSectionUtils.value(
        item,
        'systolicPressure',
      );
      final String diastolic = ReportSectionUtils.value(
        item,
        'diastolicPressure',
      );

      final String bloodPressure = systolic == '-' && diastolic == '-'
          ? '-'
          : '$systolic / $diastolic mmHg';

      widgets.add(
        ReportSectionUtils.card(
          title: 'Control del ${ReportSectionUtils.date(item, 'recordedAt')}',
          children: <pw.Widget>[
            ReportSectionUtils.field('Presión arterial', bloodPressure),
            ReportSectionUtils.field(
              'Frecuencia cardíaca',
              '${ReportSectionUtils.value(item, 'heartRate')} lpm',
            ),
            ReportSectionUtils.field(
              'Saturación de oxígeno',
              '${ReportSectionUtils.value(item, 'oxygenSaturation')} %',
            ),
            ReportSectionUtils.field(
              'Temperatura',
              '${ReportSectionUtils.value(item, 'temperature')} °C',
            ),
            ReportSectionUtils.field(
              'Peso',
              '${ReportSectionUtils.value(item, 'weight')} kg',
            ),
            ReportSectionUtils.field(
              'Glucemia',
              '${ReportSectionUtils.value(item, 'bloodGlucose')} mg/dL',
            ),
            ReportSectionUtils.field(
              'Notas',
              ReportSectionUtils.value(item, 'notes'),
            ),
          ],
        ),
      );
    }

    return ReportSectionUtils.finishSection(widgets);
  }
}
