import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class SurgeriesSection {
  const SurgeriesSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.surgeries.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Cirugías'),
    ];

    for (final Map<String, dynamic> item in report.surgeries) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'procedure',
            fallback: 'Cirugía',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Fecha',
              ReportSectionUtils.date(item, 'surgeryDate'),
            ),
            ReportSectionUtils.field(
              'Institución',
              ReportSectionUtils.value(item, 'hospital'),
            ),
            ReportSectionUtils.field(
              'Cirujano',
              ReportSectionUtils.value(item, 'surgeon'),
            ),
            ReportSectionUtils.field(
              'Motivo',
              ReportSectionUtils.value(item, 'reason'),
            ),
            ReportSectionUtils.field(
              'Complicaciones',
              ReportSectionUtils.value(item, 'complications'),
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
