import '../../../core/storage/app_storage.dart';
import '../models/medication_item.dart';

class MedicationStorageService {
  MedicationStorageService._();

  static const String _storageKey = 'medication_items';

  static List<MedicationItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <MedicationItem>[];
    }

    final List<MedicationItem> items = <MedicationItem>[];

    for (final String source in storedItems) {
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

    if (!saved) {
      throw StateError('No fue posible guardar los medicamentos.');
    }
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
}
