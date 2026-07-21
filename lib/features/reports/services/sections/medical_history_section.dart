import 'package:pdf/widgets.dart' as pw;

import '../../models/medical_report_data.dart';

class MedicalHistorySection {
  const MedicalHistorySection._();

  static List<pw.Widget> build(MedicalReportData report) {
    if (report.medicalHistory.isEmpty) {
      return <pw.Widget>[];
    }

    final List<pw.Widget> widgets = <pw.Widget>[
      pw.Header(level: 1, text: 'Historia Clínica'),
    ];

    for (final Map<String, dynamic> item in report.medicalHistory) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                (item['title'] ?? '').toString(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              pw.SizedBox(height: 4),

              pw.Text((item['description'] ?? '').toString()),

              if ((item['status'] ?? '').toString().isNotEmpty)
                pw.Text('Estado: ${item['status']}'),

              if ((item['diagnosisDate'] ?? '').toString().isNotEmpty)
                pw.Text('Diagnóstico: ${item['diagnosisDate']}'),

              if ((item['notes'] ?? '').toString().isNotEmpty)
                pw.Text('Notas: ${item['notes']}'),
            ],
          ),
        ),
      );
    }

    widgets.add(pw.SizedBox(height: 20));

    return widgets;
  }
}
