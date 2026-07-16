import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/surgery_item.dart';

class SurgeryStorageService {
  SurgeryStorageService._();

  static const String _baseStorageKey = 'surgery_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<SurgeryItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <SurgeryItem>[];
    }

    final List<SurgeryItem> items = <SurgeryItem>[];

    for (final String source in storedItems) {
      try {
        items.add(SurgeryItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort((SurgeryItem a, SurgeryItem b) {
      final DateTime aDate = a.surgeryDate ?? a.updatedAt;
      final DateTime bDate = b.surgeryDate ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    return items;
  }

  static Future<void> saveItems(List<SurgeryItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((SurgeryItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar las cirugías.');
    }
  }

  static Future<void> saveItem(SurgeryItem item) async {
    final List<SurgeryItem> items = loadItems();
    final int index = items.indexWhere(
      (SurgeryItem current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<SurgeryItem> items = loadItems()
      ..removeWhere((SurgeryItem item) => item.id == id);

    await saveItems(items);
  }
}
