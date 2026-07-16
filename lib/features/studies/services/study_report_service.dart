import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../family/services/family_storage_service.dart';
import '../models/study_item.dart';
import 'study_storage_service.dart';

class StudyReportService {
  StudyReportService._();

  static Future<File> generatePdf() async {
    final List<StudyItem> studies = StudyStorageService.loadItems();
    final String memberName = FamilyStorageService.activeMember.name;
    final pw.Document document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              'MiSalud VortexIT',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Estudios médicos de $memberName',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 18),
            if (studies.isEmpty)
              pw.Text('No hay estudios registrados.')
            else
              ...studies.map(_buildStudy),
          ];
        },
      ),
    );

    final Directory documents = await getApplicationDocumentsDirectory();
    final Directory reports = Directory(
      p.join(
        documents.path,
        'MiSalud_VortexIT',
        'reports',
        FamilyStorageService.activeMemberId,
      ),
    );

    if (!await reports.exists()) {
      await reports.create(recursive: true);
    }

    final File file = File(
      p.join(
        reports.path,
        'estudios_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );

    await file.writeAsBytes(await document.save());
    return file;
  }

  static pw.Widget _buildStudy(StudyItem study) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            study.name,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Categoría: ${study.category.label}'),
          pw.Text('Estado: ${study.status.label}'),
          if (study.studyDate != null)
            pw.Text('Fecha: ${_formatDate(study.studyDate!)}'),
          if (study.requestingDoctor.trim().isNotEmpty)
            pw.Text('Médico: ${study.requestingDoctor}'),
          if (study.institution.trim().isNotEmpty)
            pw.Text('Institución: ${study.institution}'),
          if (study.result.trim().isNotEmpty)
            pw.Text('Resultado: ${study.result}'),
          if (study.notes.trim().isNotEmpty) pw.Text('Notas: ${study.notes}'),
          if (study.attachmentOriginalName != null)
            pw.Text('Adjunto: ${study.attachmentOriginalName}'),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
