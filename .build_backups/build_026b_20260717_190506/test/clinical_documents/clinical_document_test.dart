import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/clinical_documents/models/clinical_document.dart';

void main() {
  test('Serializa y restaura un documento clínico', () {
    final now = DateTime(2026, 7, 17, 12, 30);
    final original = ClinicalDocument(
      id: 'doc-1',
      title: 'Receta',
      type: ClinicalDocumentType.prescription,
      documentDate: DateTime(2026, 7, 10),
      professional: 'Dra. Pérez',
      institution: 'Hospital Español',
      notes: 'Control en 30 días',
      fileName: 'receta.pdf',
      filePath: '/tmp/receta.pdf',
      mimeType: 'application/pdf',
      createdAt: now,
      updatedAt: now,
    );
    final restored = ClinicalDocument.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.type, ClinicalDocumentType.prescription);
    expect(restored.isPdf, isTrue);
    expect(restored.isImage, isFalse);
  });
}
