import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/allergy_item.dart';

class AllergyStorageService {
  AllergyStorageService._();

  static const String _legacyKey = 'allergy_items';
  static String get _storageKey => FamilyStorageService.scopedKey(_legacyKey);

  static List<AllergyItem> loadItems() {
    _migrateLegacyData();
    final List<String>? stored = AppStorage.readStringList(_storageKey);
    if (stored == null) return <AllergyItem>[];

    final List<AllergyItem> items = <AllergyItem>[];
    for (final String source in stored) {
      try {
        items.add(AllergyItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }
    items.sort(
      (AllergyItem a, AllergyItem b) => b.updatedAt.compareTo(a.updatedAt),
    );
    return items;
  }

  static Future<void> saveItems(List<AllergyItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((AllergyItem item) => item.toJson()).toList(),
    );
    if (!saved) throw StateError('No fue posible guardar las alergias.');
  }

  static Future<void> saveItem(AllergyItem item) async {
    final List<AllergyItem> items = loadItems();
    final int index = items.indexWhere(
      (AllergyItem current) => current.id == item.id,
    );
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<AllergyItem> items = loadItems()
      ..removeWhere((AllergyItem item) => item.id == id);
    await saveItems(items);
  }

  static void _migrateLegacyData() {
    if (AppStorage.containsKey(_storageKey)) return;
    final List<String>? legacy = AppStorage.readStringList(_legacyKey);
    if (legacy == null || legacy.isEmpty) return;
    AppStorage.saveStringList(_storageKey, legacy);
    AppStorage.remove(_legacyKey);
  }
}
