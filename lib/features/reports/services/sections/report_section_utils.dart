import 'package:pdf/widgets.dart' as pw;

class ReportSectionUtils {
  const ReportSectionUtils._();

  static String value(
    Map<String, dynamic> item,
    String key, {
    String fallback = '-',
  }) {
    final Object? rawValue = item[key];

    if (rawValue == null) {
      return fallback;
    }

    final String text = rawValue.toString().trim();

    if (text.isEmpty || text == 'null') {
      return fallback;
    }

    return _cleanEnumValue(text);
  }

  static bool hasValue(Map<String, dynamic> item, String key) {
    return value(item, key, fallback: '').isNotEmpty;
  }

  static String date(
    Map<String, dynamic> item,
    String key, {
    String fallback = '-',
  }) {
    final String rawDate = value(item, key, fallback: '');

    if (rawDate.isEmpty) {
      return fallback;
    }

    final DateTime? parsedDate = DateTime.tryParse(rawDate);

    if (parsedDate == null) {
      return rawDate;
    }

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year}';
  }

  static String dateTime(
    Map<String, dynamic> item,
    String key, {
    String fallback = '-',
  }) {
    final String rawDate = value(item, key, fallback: '');

    if (rawDate.isEmpty) {
      return fallback;
    }

    final DateTime? parsedDate = DateTime.tryParse(rawDate);

    if (parsedDate == null) {
      return rawDate;
    }

    return '${parsedDate.day.toString().padLeft(2, '0')}/'
        '${parsedDate.month.toString().padLeft(2, '0')}/'
        '${parsedDate.year} '
        '${parsedDate.hour.toString().padLeft(2, '0')}:'
        '${parsedDate.minute.toString().padLeft(2, '0')}';
  }

  static pw.Widget sectionTitle(String title) {
    return pw.Header(level: 1, text: title);
  }

  static pw.Widget card({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            title.trim().isEmpty ? 'Sin título' : title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget field(
    String label,
    String value, {
    bool hideWhenEmpty = true,
  }) {
    final String cleanValue = value.trim();

    if (hideWhenEmpty && (cleanValue.isEmpty || cleanValue == '-')) {
      return pw.SizedBox();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: cleanValue),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> finishSection(List<pw.Widget> widgets) {
    widgets.add(pw.SizedBox(height: 16));

    return widgets;
  }

  static String _cleanEnumValue(String value) {
    if (!value.contains('.')) {
      return value;
    }

    final List<String> parts = value.split('.');

    return parts.last;
  }
}
