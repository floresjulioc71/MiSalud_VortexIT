import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class MedicationsSection {
  const MedicationsSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.medications.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Medicamentos'),
    ];

    for (final Map<String, dynamic> item in report.medications) {
      widgets.add(
        ReportSectionUtils.card(
          title: ReportSectionUtils.value(
            item,
            'name',
            fallback: 'Medicamento',
          ),
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Principio activo',
              ReportSectionUtils.value(item, 'activeIngredient'),
            ),
            ReportSectionUtils.field(
              'Dosis',
              ReportSectionUtils.value(item, 'dose'),
            ),
            ReportSectionUtils.field(
              'Frecuencia',
              ReportSectionUtils.value(item, 'frequency'),
            ),
            ReportSectionUtils.field(
              'Horario',
              ReportSectionUtils.value(item, 'schedule'),
            ),
            ReportSectionUtils.field(
              'Vía',
              ReportSectionUtils.value(item, 'route'),
            ),
            ReportSectionUtils.field(
              'Estado',
              ReportSectionUtils.value(item, 'status'),
            ),
            ReportSectionUtils.field(
              'Fecha de inicio',
              ReportSectionUtils.date(item, 'startDate'),
            ),
            ReportSectionUtils.field(
              'Fecha de finalización',
              ReportSectionUtils.date(item, 'endDate'),
            ),
            ReportSectionUtils.field(
              'Prescripto por',
              ReportSectionUtils.value(item, 'prescribedBy'),
            ),
            ReportSectionUtils.field(
              'Indicaciones',
              ReportSectionUtils.value(item, 'instructions'),
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
