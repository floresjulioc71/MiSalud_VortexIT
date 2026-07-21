import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class AllergiesSection {
  const AllergiesSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.allergies.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Alergias'),
    ];

    for (final Map<String, dynamic> item in report.allergies) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'allergen',
            fallback: 'Alergia',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Tipo',
              ReportSectionUtils.value(item, 'type'),
            ),
            ReportSectionUtils.field(
              'Gravedad',
              ReportSectionUtils.value(item, 'severity'),
            ),
            ReportSectionUtils.field(
              'Reacción',
              ReportSectionUtils.value(item, 'reaction'),
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
