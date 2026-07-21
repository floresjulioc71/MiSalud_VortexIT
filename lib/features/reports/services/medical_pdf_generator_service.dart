import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/medical_report_data.dart';
import 'pdf_report_service.dart';
import 'sections/allergies_section.dart';
import 'sections/clinical_documents_section.dart';
import 'sections/consultations_section.dart';
import 'sections/doctors_section.dart';
import 'sections/health_controls_section.dart';
import 'sections/medical_history_section.dart';
import 'sections/medical_studies_section.dart';
import 'sections/medications_section.dart';
import 'sections/profile_section.dart';
import 'sections/surgeries_section.dart';
import 'sections/vaccines_section.dart';

class MedicalPdfGeneratorService {
  const MedicalPdfGeneratorService._();

  static Future<File> generate(MedicalReportData report) async {
    final pw.Document pdf = pw.Document(
      title: 'Historia Clínica - ${report.patientName}',
      author: 'MiSalud VortexIT',
      subject: 'Reporte médico personal',
      creator: 'MiSalud VortexIT',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 40),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              'MiSalud VortexIT - ${report.patientName}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          );
        },
        build: (pw.Context context) => <pw.Widget>[
          pw.Header(
            level: 0,
            child: pw.Text(
              'MiSalud VortexIT',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Historia Clínica Personal',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Paciente: ${report.patientName}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Fecha de generación: ${_formatDateTime(report.generatedAt)}',
          ),
          pw.Divider(),
          ...ProfileSection.build(report),
          pw.Header(level: 1, text: 'Resumen Clínico'),
          pw.Bullet(
            text: 'Antecedentes médicos: ${report.medicalHistory.length}',
          ),
          pw.Bullet(text: 'Alergias: ${report.allergies.length}'),
          pw.Bullet(text: 'Medicamentos: ${report.medications.length}'),
          pw.Bullet(text: 'Vacunas: ${report.vaccines.length}'),
          pw.Bullet(text: 'Cirugías: ${report.surgeries.length}'),
          pw.Bullet(text: 'Estudios médicos: ${report.medicalStudies.length}'),
          pw.Bullet(
            text: 'Documentos clínicos: ${report.clinicalDocuments.length}',
          ),
          pw.Bullet(text: 'Médicos: ${report.doctors.length}'),
          pw.Bullet(text: 'Consultas: ${report.consultations.length}'),
          pw.Bullet(
            text: 'Controles de salud: ${report.healthControls.length}',
          ),
          pw.SizedBox(height: 18),
          ...MedicalHistorySection.build(report),
          ...AllergiesSection.build(report),
          ...MedicationsSection.build(report),
          ...VaccinesSection.build(report),
          ...SurgeriesSection.build(report),
          ...MedicalStudiesSection.build(report),
          ...ClinicalDocumentsSection.build(report),
          ...DoctorsSection.build(report),
          ...ConsultationsSection.build(report),
          ...HealthControlsSection.build(report),
        ],
      ),
    );

    final File output = await PdfReportService.createOutputFile(
      patientName: report.patientName,
    );

    await output.writeAsBytes(await pdf.save(), flush: true);

    return output;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
