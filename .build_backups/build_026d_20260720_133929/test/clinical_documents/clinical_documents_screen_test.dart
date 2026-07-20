import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/clinical_documents/screens/clinical_documents_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Muestra el estado vacío del módulo', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MaterialApp(home: ClinicalDocumentsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Documentos clínicos'), findsOneWidget);
    expect(find.text('Todavía no hay documentos'), findsOneWidget);
    expect(find.text('Agregar'), findsOneWidget);
  });
}
