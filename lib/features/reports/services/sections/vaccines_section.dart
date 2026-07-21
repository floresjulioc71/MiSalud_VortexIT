import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class VaccinesSection {
  const VaccinesSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.vaccines.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Vacunas'),
    ];

    for (final Map<String, dynamic> item in report.vaccines) {
      final String doseNumber = ReportSectionUtils.value(item, 'doseNumber');
      final String totalDoses = ReportSectionUtils.value(item, 'totalDoses');

      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(item, 'name', fallback: 'Vacuna'),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Enfermedad',
              ReportSectionUtils.value(item, 'disease'),
            ),
            ReportSectionUtils.field(
              'Dosis',
              ReportSectionUtils.value(item, 'dose'),
            ),
            ReportSectionUtils.field(
              'Número de dosis',
              doseNumber == '-' || totalDoses == '-'
                  ? doseNumber
                  : '$doseNumber de $totalDoses',
            ),
            ReportSectionUtils.field(
              'Fecha de aplicación',
              ReportSectionUtils.date(item, 'applicationDate'),
            ),
            ReportSectionUtils.field(
              'Laboratorio',
              ReportSectionUtils.value(item, 'laboratory'),
            ),
            ReportSectionUtils.field(
              'Lote',
              ReportSectionUtils.value(item, 'lotNumber'),
            ),
            ReportSectionUtils.field(
              'Lugar de aplicación',
              ReportSectionUtils.value(item, 'applicationPlace'),
            ),
            ReportSectionUtils.field(
              'Profesional',
              ReportSectionUtils.value(item, 'professional'),
            ),
            ReportSectionUtils.field(
              'Próxima dosis',
              ReportSectionUtils.date(item, 'nextDoseDate'),
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
