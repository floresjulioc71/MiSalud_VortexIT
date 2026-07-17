import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../diagnoses/models/diagnosis_entry.dart';
import '../models/consultation_item.dart';

class ConsultationTimelinePdfService {
  ConsultationTimelinePdfService._();

  static Future<void> printPdf({
    required List<ConsultationItem> items,
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchText = '',
  }) async {
    final Uint8List bytes = await _buildValidatedPdf(
      items: items,
      doctorFilter: doctorFilter,
      diagnosisFilter: diagnosisFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      searchText: searchText,
    );

    await Printing.layoutPdf(
      name: fileName,
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  static Future<String?> savePdf({
    required List<ConsultationItem> items,
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchText = '',
  }) async {
    final Uint8List bytes = await _buildValidatedPdf(
      items: items,
      doctorFilter: doctorFilter,
      diagnosisFilter: diagnosisFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      searchText: searchText,
    );

    const XTypeGroup pdfType = XTypeGroup(
      label: 'Documento PDF',
      extensions: <String>['pdf'],
    );

    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: const <XTypeGroup>[pdfType],
      confirmButtonText: 'Guardar',
    );

    if (location == null) {
      return null;
    }

    final XFile file = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: fileName,
    );

    await file.saveTo(location.path);
    return location.path;
  }

  static Future<void> sharePdf({
    required List<ConsultationItem> items,
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchText = '',
  }) async {
    final Uint8List bytes = await _buildValidatedPdf(
      items: items,
      doctorFilter: doctorFilter,
      diagnosisFilter: diagnosisFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      searchText: searchText,
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<Uint8List> _buildValidatedPdf({
    required List<ConsultationItem> items,
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchText = '',
  }) async {
    if (items.isEmpty) {
      throw StateError('No hay consultas para exportar.');
    }

    return buildPdf(
      items: items,
      doctorFilter: doctorFilter,
      diagnosisFilter: diagnosisFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      searchText: searchText,
    );
  }

  static Future<Uint8List> buildPdf({
    required List<ConsultationItem> items,
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String searchText = '',
  }) async {
    final List<ConsultationItem> ordered = List<ConsultationItem>.from(items)
      ..sort(
        (ConsultationItem a, ConsultationItem b) =>
            b.consultationDateTime.compareTo(a.consultationDateTime),
      );

    final Set<String> doctors = ordered
        .map((ConsultationItem item) => item.doctorNameSnapshot.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();

    final Set<String> diagnoses = <String>{};

    for (final ConsultationItem item in ordered) {
      for (final DiagnosisEntry diagnosis in item.diagnoses) {
        final String value = diagnosis.description.trim();

        if (value.isNotEmpty) {
          diagnoses.add(value);
        }
      }
    }

    final pw.Document document = pw.Document(
      title: 'Evolución clínica',
      author: 'MiSalud VortexIT',
      subject: 'Historia de consultas médicas',
      creator: 'MiSalud_VortexIT',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => _buildHeader(context),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'Evolución clínica',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Informe generado por MiSalud VortexIT',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _buildSummary(
            consultationCount: ordered.length,
            doctorCount: doctors.length,
            diagnosisCount: diagnoses.length,
          ),
          if (_hasFilters(
            doctorFilter: doctorFilter,
            diagnosisFilter: diagnosisFilter,
            dateFrom: dateFrom,
            dateTo: dateTo,
            searchText: searchText,
          )) ...<pw.Widget>[
            pw.SizedBox(height: 12),
            _buildFilters(
              doctorFilter: doctorFilter,
              diagnosisFilter: diagnosisFilter,
              dateFrom: dateFrom,
              dateTo: dateTo,
              searchText: searchText,
            ),
          ],
          pw.SizedBox(height: 18),
          ...ordered.expand(
            (ConsultationItem item) => <pw.Widget>[
              _buildConsultation(item),
              pw.SizedBox(height: 12),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Este documento es un registro personal y no reemplaza '
            'la documentación emitida por profesionales o instituciones '
            'de salud.',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildHeader(pw.Context context) {
    if (context.pageNumber == 1) {
      return pw.SizedBox();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'MiSalud VortexIT',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Evolución clínica',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      margin: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Generado: ${_formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary({
    required int consultationCount,
    required int doctorCount,
    required int diagnosisCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.7),
      ),
      child: pw.Row(
        children: <pw.Widget>[
          _summaryCell('Consultas', consultationCount),
          _summaryCell('Médicos', doctorCount),
          _summaryCell('Diagnósticos', diagnosisCount),
        ],
      ),
    );
  }

  static pw.Widget _summaryCell(String label, int value) {
    return pw.Expanded(
      child: pw.Column(
        children: <pw.Widget>[
          pw.Text(
            value.toString(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFilters({
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    required String searchText,
  }) {
    final List<String> values = <String>[];

    if (doctorFilter != null && doctorFilter.trim().isNotEmpty) {
      values.add('Médico: ${doctorFilter.trim()}');
    }

    if (diagnosisFilter != null && diagnosisFilter.trim().isNotEmpty) {
      values.add('Diagnóstico: ${diagnosisFilter.trim()}');
    }

    if (dateFrom != null) {
      values.add('Desde: ${_formatDate(dateFrom)}');
    }

    if (dateTo != null) {
      values.add('Hasta: ${_formatDate(dateTo)}');
    }

    if (searchText.trim().isNotEmpty) {
      values.add('Búsqueda: ${searchText.trim()}');
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Filtros aplicados',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(values.join(' • '), style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildConsultation(ConsultationItem item) {
    final List<pw.Widget> details = <pw.Widget>[
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              _formatDateTime(item.consultationDateTime),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
          if (item.nextControlDate != null)
            pw.Text(
              'Próximo control: '
              '${_formatDate(item.nextControlDate!)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
        ],
      ),
    ];

    final String doctor = item.doctorNameSnapshot.trim();
    final String specialty = item.specialtySnapshot.trim();

    if (doctor.isNotEmpty || specialty.isNotEmpty) {
      details.add(pw.SizedBox(height: 5));
      details.add(
        _field(
          'Profesional',
          <String>[
            if (doctor.isNotEmpty) doctor,
            if (specialty.isNotEmpty) specialty,
          ].join(' • '),
        ),
      );
    }

    _addField(details, 'Motivo', item.reason);

    if (item.diagnoses.isNotEmpty) {
      final String diagnosisText = item.diagnoses
          .map((DiagnosisEntry diagnosis) {
            final String description = diagnosis.description.trim();
            final String code = diagnosis.primaryCode.trim();

            if (code.isEmpty) {
              return description;
            }

            return '$description ($code)';
          })
          .where((String value) => value.isNotEmpty)
          .join(', ');

      _addField(details, 'Diagnósticos', diagnosisText);
    }

    _addField(details, 'Tratamiento', item.treatment);
    _addField(details, 'Medicación recetada', item.prescribedMedication);
    _addField(details, 'Estudios solicitados', item.requestedStudies);
    _addField(details, 'Observaciones', item.notes);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200, width: 0.7),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: details,
      ),
    );
  }

  static void _addField(List<pw.Widget> widgets, String label, String value) {
    final String text = value.trim();

    if (text.isEmpty) {
      return;
    }

    widgets.add(pw.SizedBox(height: 6));
    widgets.add(_field(label, text));
  }

  static pw.Widget _field(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: <pw.InlineSpan>[
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static bool _hasFilters({
    String? doctorFilter,
    String? diagnosisFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    required String searchText,
  }) {
    return doctorFilter?.trim().isNotEmpty == true ||
        diagnosisFilter?.trim().isNotEmpty == true ||
        dateFrom != null ||
        dateTo != null ||
        searchText.trim().isNotEmpty;
  }

  static String get fileName {
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');

    return 'Evolucion_Clinica_$year-$month-$day.pdf';
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  static String _formatDateTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '${_formatDate(value)} $hour:$minute';
  }
}
