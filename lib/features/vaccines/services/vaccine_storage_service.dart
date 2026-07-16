import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/vaccine_item.dart';

class VaccineStorageService {
  VaccineStorageService._();

  static const String _baseStorageKey = 'vaccine_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<VaccineItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <VaccineItem>[];
    }

    final List<VaccineItem> items = <VaccineItem>[];

    for (final String source in storedItems) {
      try {
        items.add(VaccineItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort((VaccineItem a, VaccineItem b) {
      final DateTime aDate = a.applicationDate ?? a.updatedAt;
      final DateTime bDate = b.applicationDate ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return items;
  }

  static Future<void> saveItems(List<VaccineItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((VaccineItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar las vacunas.');
    }
  }

  static Future<void> saveItem(VaccineItem item) async {
    final List<VaccineItem> items = loadItems();
    final int index = items.indexWhere(
      (VaccineItem current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<VaccineItem> items = loadItems()
      ..removeWhere((VaccineItem item) => item.id == id);

    await saveItems(items);
  }
}
