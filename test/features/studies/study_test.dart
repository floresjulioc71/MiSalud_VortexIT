import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misalud_vortexit/core/storage/app_storage.dart';
import 'package:misalud_vortexit/features/family/models/family_member.dart';
import 'package:misalud_vortexit/features/family/services/family_storage_service.dart';
import 'package:misalud_vortexit/features/studies/models/study_item.dart';
import 'package:misalud_vortexit/features/studies/services/study_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppStorage.initialize();
    await FamilyStorageService.initialize();
  });

  test('Guarda y recupera un estudio', () async {
    final DateTime now = DateTime.now();

    final StudyItem item = StudyItem(
      id: '1',
      name: 'Hemograma',
      category: StudyCategory.laboratory,
      status: StudyStatus.completed,
      studyDate: DateTime(2026, 7, 1),
      result: 'Sin alteraciones',
      attachmentOriginalName: 'hemograma.pdf',
      attachmentType: StudyAttachmentType.pdf,
      createdAt: now,
      updatedAt: now,
    );

    await StudyStorageService.saveItem(item);

    final List<StudyItem> restored = StudyStorageService.loadItems();

    expect(restored, hasLength(1));
    expect(restored.first.name, 'Hemograma');
    expect(restored.first.category, StudyCategory.laboratory);
    expect(restored.first.attachmentType, StudyAttachmentType.pdf);
  });

  test('Mantiene estudios separados por integrante', () async {
    final List<FamilyMember> members = FamilyStorageService.loadMembers();

    final DateTime now = DateTime.now();
    const String secondId = 'second_member';

    await FamilyStorageService.saveMember(
      FamilyMember(
        id: secondId,
        name: 'Segundo integrante',
        relationship: 'Familia',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(members.first.id);

    await StudyStorageService.saveItem(
      StudyItem(
        id: 'first',
        name: 'Estudio del primer integrante',
        category: StudyCategory.other,
        status: StudyStatus.completed,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await FamilyStorageService.setActiveMember(secondId);

    expect(StudyStorageService.loadItems(), isEmpty);

    await StudyStorageService.saveItem(
      StudyItem(
        id: 'second',
        name: 'Estudio del segundo integrante',
        category: StudyCategory.other,
        status: StudyStatus.completed,
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(
      StudyStorageService.loadItems().first.name,
      'Estudio del segundo integrante',
    );
  });
}
