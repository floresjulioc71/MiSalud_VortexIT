import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';

class ProfileSection {
  const ProfileSection._();

  static List<pw.Widget> build(MedicalReportData report) {
    final Map<String, dynamic> profile = report.profile;

    if (profile.isEmpty) {
      return <pw.Widget>[];
    }

    String value(String key) {
      final Object? data = profile[key];

      if (data == null) {
        return '-';
      }

      final String text = data.toString().trim();

      return text.isEmpty ? '-' : text;
    }

    return <pw.Widget>[
      pw.Header(level: 1, text: 'Perfil Médico'),

      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(5),
        },
        children: [
          row('Nombre', value('fullName')),
          row('Documento', value('documentNumber')),
          row('Grupo sanguíneo', value('bloodType')),
          row('Obra Social', value('healthInsurance')),
          row('Afiliado', value('membershipNumber')),
          row('Contacto de emergencia', value('emergencyContactName')),
          row('Teléfono', value('emergencyContactPhone')),
        ],
      ),

      pw.SizedBox(height: 20),
    ];
  }

  static pw.TableRow row(String title, String value) {
    return pw.TableRow(children: [cellTitle(title), cellValue(value)]);
  }

  static pw.Widget cellTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget cellValue(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text),
    );
  }
}
