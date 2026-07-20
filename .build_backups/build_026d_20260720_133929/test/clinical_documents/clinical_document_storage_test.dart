import 'package:flutter_test/flutter_test.dart';
import 'package:misalud_vortexit/features/clinical_documents/models/clinical_document.dart';
import 'package:misalud_vortexit/features/clinical_documents/services/clinical_document_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ClinicalDocumentStorageService.initialize();
  });
  ClinicalDocument item(String id, String title) {
    final now = DateTime(2026, 7, 17);
    return ClinicalDocument(
      id: id,
      title: title,
      type: ClinicalDocumentType.other,
      documentDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('Guarda y carga documentos', () async {
    await ClinicalDocumentStorageService.saveItem(item('1', 'Documento'));
    expect(
      ClinicalDocumentStorageService.loadItems().single.title,
      'Documento',
    );
  });
  test('Mantiene documentos separados por integrante', () async {
    final p = await SharedPreferences.getInstance();
    await p.setString('selected_family_member_id', 'member-1');
    await ClinicalDocumentStorageService.saveItem(item('1', 'Integrante 1'));
    await p.setString('selected_family_member_id', 'member-2');
    expect(ClinicalDocumentStorageService.loadItems(), isEmpty);
    await ClinicalDocumentStorageService.saveItem(item('2', 'Integrante 2'));
    expect(
      ClinicalDocumentStorageService.loadItems().single.title,
      'Integrante 2',
    );
    await p.setString('selected_family_member_id', 'member-1');
    expect(
      ClinicalDocumentStorageService.loadItems().single.title,
      'Integrante 1',
    );
  });
  test('Actualiza y elimina un documento', () async {
    await ClinicalDocumentStorageService.saveItem(item('1', 'Original'));
    await ClinicalDocumentStorageService.saveItem(item('1', 'Actualizado'));
    expect(
      ClinicalDocumentStorageService.loadItems().single.title,
      'Actualizado',
    );
    await ClinicalDocumentStorageService.deleteItem('1');
    expect(ClinicalDocumentStorageService.loadItems(), isEmpty);
  });
}
