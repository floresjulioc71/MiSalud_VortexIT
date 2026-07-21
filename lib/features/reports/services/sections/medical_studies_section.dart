import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class MedicalStudiesSection {
  const MedicalStudiesSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.medicalStudies.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Estudios Médicos'),
    ];

    for (final Map<String, dynamic> item in report.medicalStudies) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'name',
            fallback: 'Estudio médico',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Fecha',
              ReportSectionUtils.date(item, 'studyDate'),
            ),
            ReportSectionUtils.field(
              'Tipo',
              ReportSectionUtils.value(item, 'type'),
            ),
            ReportSectionUtils.field(
              'Estado',
              ReportSectionUtils.value(item, 'status'),
            ),
            ReportSectionUtils.field(
              'Centro médico',
              ReportSectionUtils.value(item, 'medicalCenter'),
            ),
            ReportSectionUtils.field(
              'Profesional',
              ReportSectionUtils.value(item, 'professional'),
            ),
            ReportSectionUtils.field(
              'Resultado',
              ReportSectionUtils.value(item, 'result'),
            ),
            ReportSectionUtils.field(
              'Próximo control',
              ReportSectionUtils.date(item, 'nextCheckDate'),
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
