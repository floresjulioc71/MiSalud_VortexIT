import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/clinical_documents/models/clinical_document.dart';
import 'package:misalud_vortexit/features/clinical_documents/screens/clinical_document_view_screen.dart';

void main() {
  testWidgets('La vista muestra los datos sin archivo adjunto', (
    WidgetTester tester,
  ) async {
    final DateTime now = DateTime(2026, 7, 20);

    final ClinicalDocument document = ClinicalDocument(
      id: 'doc-1',
      title: 'Certificado clínico',
      type: ClinicalDocumentType.certificate,
      documentDate: now,
      professional: 'Dra. Ana Pérez',
      institution: 'Clínica Central',
      notes: 'Control anual',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(home: ClinicalDocumentViewScreen(document: document)),
    );

    expect(find.text('Certificado clínico'), findsOneWidget);
    expect(find.text('Certificado'), findsOneWidget);
    expect(find.text('Dra. Ana Pérez'), findsOneWidget);
    expect(find.text('Clínica Central'), findsOneWidget);
    expect(
      find.text('Este registro no tiene un archivo adjunto.'),
      findsOneWidget,
    );
  });
}
