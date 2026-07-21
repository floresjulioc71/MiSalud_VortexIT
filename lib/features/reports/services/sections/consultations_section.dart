import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class ConsultationsSection {
  const ConsultationsSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.consultations.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Consultas Médicas'),
    ];

    for (final Map<String, dynamic> item in report.consultations) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'reason',
            fallback: 'Consulta médica',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Fecha',
              ReportSectionUtils.dateTime(item, 'consultationDateTime'),
            ),
            ReportSectionUtils.field(
              'Médico',
              ReportSectionUtils.value(item, 'doctorNameSnapshot'),
            ),
            ReportSectionUtils.field(
              'Especialidad',
              ReportSectionUtils.value(item, 'specialtySnapshot'),
            ),
            ReportSectionUtils.field(
              'Tratamiento',
              ReportSectionUtils.value(item, 'treatment'),
            ),
            ReportSectionUtils.field(
              'Medicamento indicado',
              ReportSectionUtils.value(item, 'prescribedMedication'),
            ),
            ReportSectionUtils.field(
              'Estudios solicitados',
              ReportSectionUtils.value(item, 'requestedStudies'),
            ),
            ReportSectionUtils.field(
              'Próximo control',
              ReportSectionUtils.date(item, 'nextControlDate'),
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
