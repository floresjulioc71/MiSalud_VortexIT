import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/health_control.dart';

class HealthControlPdfService {
  HealthControlPdfService._();

  static Future<Uint8List> buildPdf({
    required List<HealthControl> items,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    if (items.isEmpty) {
      throw StateError('No hay controles para exportar.');
    }

    final List<HealthControl> ordered = List<HealthControl>.from(items)
      ..sort(
        (HealthControl a, HealthControl b) =>
            b.recordedAt.compareTo(a.recordedAt),
      );

    final pw.Document document = pw.Document(
      title: 'Controles de Salud',
      author: 'MiSalud VortexIT',
      creator: 'MiSalud_VortexIT',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'Generado: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (pw.Context context) => <pw.Widget>[
          pw.Text(
            'Controles de Salud',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('MiSalud VortexIT', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey50,
              border: pw.Border.all(color: PdfColors.blueGrey200),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text('Cantidad de controles: ${ordered.length}'),
                pw.SizedBox(height: 4),
                pw.Text('Período: ${_periodLabel(dateFrom, dateTo)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          ...ordered.expand(
            (HealthControl item) => <pw.Widget>[
              _controlCard(item),
              pw.SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<void> printOrSave({
    required List<HealthControl> items,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Uint8List bytes = await buildPdf(
      items: items,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    await Printing.layoutPdf(
      name: fileName(dateFrom, dateTo),
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  static Future<String?> saveFile({
    required List<HealthControl> items,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Uint8List bytes = await buildPdf(
      items: items,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: fileName(dateFrom, dateTo),
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'PDF', extensions: <String>['pdf']),
      ],
    );
    if (location == null) {
      return null;
    }
    final File file = File(location.path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> share({
    required List<HealthControl> items,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final Uint8List bytes = await buildPdf(
      items: items,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    await Printing.sharePdf(bytes: bytes, filename: fileName(dateFrom, dateTo));
  }

  static String fileName(DateTime? dateFrom, DateTime? dateTo) {
    if (dateFrom != null && dateTo != null) {
      return 'Controles_Salud_${_fileDate(dateFrom)}_al_${_fileDate(dateTo)}.pdf';
    }
    return 'Controles_Salud_${_fileDate(DateTime.now())}.pdf';
  }

  static pw.Widget _controlCard(HealthControl item) {
    final List<pw.Widget> rows = <pw.Widget>[
      pw.Text(
        _formatDateTime(item.recordedAt),
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    ];
    void add(String label, String value) {
      rows.add(pw.SizedBox(height: 4));
      rows.add(
        pw.RichText(
          text: pw.TextSpan(
            children: <pw.InlineSpan>[
              pw.TextSpan(
                text: '$label: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(text: value),
            ],
          ),
        ),
      );
    }

    if (item.systolicPressure != null || item.diastolicPressure != null) {
      add(
        'Presión arterial',
        '${item.systolicPressure ?? '-'} / ${item.diastolicPressure ?? '-'} mmHg',
      );
    }
    if (item.heartRate != null) {
      add('Frecuencia cardíaca', '${item.heartRate} lpm');
    }
    if (item.oxygenSaturation != null) {
      add('Saturación de oxígeno', '${item.oxygenSaturation} %');
    }
    if (item.temperature != null) {
      add('Temperatura', '${item.temperature!.toStringAsFixed(1)} °C');
    }
    if (item.weight != null) {
      add('Peso', '${item.weight!.toStringAsFixed(1)} kg');
    }
    if (item.bloodGlucose != null) {
      add('Glucemia', '${item.bloodGlucose!.toStringAsFixed(0)} mg/dL');
    }
    if (item.notes.trim().isNotEmpty) add('Observaciones', item.notes.trim());

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey200),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  static String _periodLabel(DateTime? from, DateTime? to) {
    if (from == null && to == null) return 'Todos los registros';
    if (from != null && to != null) {
      return '${_formatDate(from)} al ${_formatDate(to)}';
    }
    if (from != null) return 'Desde ${_formatDate(from)}';
    return 'Hasta ${_formatDate(to!)}';
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _formatDateTime(DateTime value) =>
      '${_formatDate(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  static String _fileDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
