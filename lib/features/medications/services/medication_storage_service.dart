import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/medication_item.dart';

class MedicationStorageService {
  MedicationStorageService._();

  static const String _legacyKey = 'medication_items';
  static String get _storageKey => FamilyStorageService.scopedKey(_legacyKey);

  static List<MedicationItem> loadItems() {
    _migrateLegacyData();
    final List<String>? stored = AppStorage.readStringList(_storageKey);
    if (stored == null) return <MedicationItem>[];

    final List<MedicationItem> items = <MedicationItem>[];
    for (final String source in stored) {
      try {
        items.add(MedicationItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }
    items.sort(
      (MedicationItem a, MedicationItem b) =>
          b.updatedAt.compareTo(a.updatedAt),
    );
    return items;
  }

  static Future<void> saveItems(List<MedicationItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((MedicationItem item) => item.toJson()).toList(),
    );
    if (!saved) throw StateError('No fue posible guardar los medicamentos.');
  }

  static Future<void> saveItem(MedicationItem item) async {
    final List<MedicationItem> items = loadItems();
    final int index = items.indexWhere(
      (MedicationItem current) => current.id == item.id,
    );
    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<MedicationItem> items = loadItems()
      ..removeWhere((MedicationItem item) => item.id == id);
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
