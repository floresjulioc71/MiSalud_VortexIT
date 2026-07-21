import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';
import 'report_section_utils.dart';

class DoctorsSection {
  const DoctorsSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.doctors.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      ReportSectionUtils.sectionTitle('Médicos'),
    ];

    for (final Map<String, dynamic> item in report.doctors) {
      final String firstName = ReportSectionUtils.value(
        item,
        'firstName',
        fallback: '',
      );
      final String lastName = ReportSectionUtils.value(
        item,
        'lastName',
        fallback: '',
      );

      final String fullName = '$firstName $lastName'.trim();

      widgets.add(
        ReportSectionUtils.card(
          title: fullName.isEmpty ? 'Profesional médico' : fullName,
          children: <pw.Widget>[
            ReportSectionUtils.field(
              'Especialidad',
              ReportSectionUtils.value(item, 'specialty'),
            ),
            ReportSectionUtils.field(
              'Matrícula',
              ReportSectionUtils.value(item, 'licenseNumber'),
            ),
            ReportSectionUtils.field(
              'Teléfono',
              ReportSectionUtils.value(item, 'phone'),
            ),
            ReportSectionUtils.field(
              'Celular',
              ReportSectionUtils.value(item, 'mobile'),
            ),
            ReportSectionUtils.field(
              'Correo',
              ReportSectionUtils.value(item, 'email'),
            ),
            ReportSectionUtils.field(
              'Institución',
              ReportSectionUtils.value(item, 'institution'),
            ),
            ReportSectionUtils.field(
              'Consultorio',
              ReportSectionUtils.value(item, 'office'),
            ),
            ReportSectionUtils.field(
              'Dirección',
              ReportSectionUtils.value(item, 'address'),
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
