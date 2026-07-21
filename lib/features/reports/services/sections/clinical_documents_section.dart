import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class ClinicalDocumentsSection {
  const ClinicalDocumentsSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.clinicalDocuments.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Documentos Clínicos'),
    ];

    for (final Map<String, dynamic> item in report.clinicalDocuments) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'title',
            fallback: 'Documento clínico',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Tipo',
              ReportSectionUtils.value(item, 'type'),
            ),
            ReportSectionUtils.field(
              'Fecha',
              ReportSectionUtils.date(item, 'documentDate'),
            ),
            ReportSectionUtils.field(
              'Profesional',
              ReportSectionUtils.value(item, 'professional'),
            ),
            ReportSectionUtils.field(
              'Institución',
              ReportSectionUtils.value(item, 'institution'),
            ),
            ReportSectionUtils.field(
              'Archivo',
              ReportSectionUtils.value(item, 'fileName'),
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
