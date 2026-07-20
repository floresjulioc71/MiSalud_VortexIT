import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/clinical_documents/models/clinical_document.dart';
import 'package:misalud_vortexit/features/clinical_documents/screens/clinical_document_view_screen.dart';

void main() {
  group('Build 026D - aceptación final', () {
    testWidgets('muestra correctamente un documento sin archivo adjunto', (
      WidgetTester tester,
    ) async {
      final DateTime date = DateTime(2026, 7, 20);

      final ClinicalDocument document = ClinicalDocument(
        id: 'doc-without-file',
        title: 'Control clínico',
        type: ClinicalDocumentType.certificate,
        documentDate: date,
        professional: 'Dra. Ana Pérez',
        institution: 'Clínica Central',
        notes: 'Control anual',
        createdAt: date,
        updatedAt: date,
      );

      await tester.pumpWidget(
        MaterialApp(home: ClinicalDocumentViewScreen(document: document)),
      );

      expect(find.text('Control clínico'), findsOneWidget);
      expect(find.text('Dra. Ana Pérez'), findsOneWidget);
      expect(find.text('Clínica Central'), findsOneWidget);
      expect(
        find.text('Este registro no tiene un archivo adjunto.'),
        findsOneWidget,
      );
      expect(find.text('Abrir'), findsNothing);
      expect(find.text('Compartir'), findsNothing);
    });

    testWidgets('muestra datos clínicos principales en la vista de detalle', (
      WidgetTester tester,
    ) async {
      final DateTime date = DateTime(2026, 5, 9);

      final ClinicalDocument document = ClinicalDocument(
        id: 'doc-details',
        title: 'Orden de laboratorio',
        type: ClinicalDocumentType.medicalOrder,
        documentDate: date,
        professional: 'Dr. Carlos Gómez',
        institution: 'Hospital General',
        notes: 'Hemograma completo',
        createdAt: date,
        updatedAt: date,
      );

      await tester.pumpWidget(
        MaterialApp(home: ClinicalDocumentViewScreen(document: document)),
      );

      expect(find.text('Orden de laboratorio'), findsOneWidget);
      expect(find.text('Orden médica'), findsOneWidget);
      expect(find.text('09/05/2026'), findsOneWidget);
      expect(find.text('Dr. Carlos Gómez'), findsOneWidget);
      expect(find.text('Hospital General'), findsOneWidget);
      expect(find.text('Hemograma completo'), findsOneWidget);
    });

    testWidgets('el botón editar ejecuta la acción configurada', (
      WidgetTester tester,
    ) async {
      bool edited = false;
      final DateTime date = DateTime(2026, 1, 1);

      final ClinicalDocument document = ClinicalDocument(
        id: 'doc-edit',
        title: 'Documento editable',
        type: ClinicalDocumentType.other,
        documentDate: date,
        createdAt: date,
        updatedAt: date,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ClinicalDocumentViewScreen(
            document: document,
            onEdit: () => edited = true,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Editar'));
      await tester.pump();

      expect(edited, isTrue);
    });
  });
}
