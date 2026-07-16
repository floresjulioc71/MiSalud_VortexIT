import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/study_item.dart';

class StudyStorageService {
  StudyStorageService._();

  static const String _baseStorageKey = 'study_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<StudyItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <StudyItem>[];
    }

    final List<StudyItem> items = <StudyItem>[];

    for (final String source in storedItems) {
      try {
        items.add(StudyItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort((StudyItem a, StudyItem b) {
      final DateTime aDate = a.studyDate ?? a.updatedAt;
      final DateTime bDate = b.studyDate ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return items;
  }

  static Future<void> saveItems(List<StudyItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((StudyItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar los estudios.');
    }
  }

  static Future<void> saveItem(StudyItem item) async {
    final List<StudyItem> items = loadItems();
    final int index = items.indexWhere(
      (StudyItem current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<StudyItem> items = loadItems()
      ..removeWhere((StudyItem item) => item.id == id);

    await saveItems(items);
  }
}
