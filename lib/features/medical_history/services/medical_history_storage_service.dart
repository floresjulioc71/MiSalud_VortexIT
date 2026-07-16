import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/medical_history_item.dart';

class MedicalHistoryStorageService {
  MedicalHistoryStorageService._();

  static const String _legacyStorageKey = 'medical_history_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_legacyStorageKey);

  static List<MedicalHistoryItem> loadItems() {
    _migrateLegacyData();

    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <MedicalHistoryItem>[];
    }

    final List<MedicalHistoryItem> items = <MedicalHistoryItem>[];

    for (final String source in storedItems) {
      try {
        items.add(MedicalHistoryItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort(
      (MedicalHistoryItem a, MedicalHistoryItem b) =>
          b.updatedAt.compareTo(a.updatedAt),
    );

    return items;
  }

  static Future<void> saveItems(List<MedicalHistoryItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((MedicalHistoryItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar los antecedentes médicos.');
    }
  }

  static Future<void> saveItem(MedicalHistoryItem item) async {
    final List<MedicalHistoryItem> items = loadItems();
    final int index = items.indexWhere(
      (MedicalHistoryItem current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<MedicalHistoryItem> items = loadItems()
      ..removeWhere((MedicalHistoryItem item) => item.id == id);

    await saveItems(items);
  }

  static void _migrateLegacyData() {
    if (AppStorage.containsKey(_storageKey)) {
      return;
    }

    final List<String>? legacy = AppStorage.readStringList(_legacyStorageKey);

    if (legacy == null || legacy.isEmpty) {
      return;
    }

    AppStorage.saveStringList(_storageKey, legacy);
    AppStorage.remove(_legacyStorageKey);
  }
}
