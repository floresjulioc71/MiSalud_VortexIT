import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/consultation_item.dart';

class ConsultationStorageService {
  ConsultationStorageService._();

  static const String _baseStorageKey = 'consultation_items';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<ConsultationItem> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <ConsultationItem>[];
    }

    final List<ConsultationItem> items = <ConsultationItem>[];

    for (final String source in storedItems) {
      try {
        items.add(ConsultationItem.fromJson(source));
      } on FormatException {
        continue;
      }
    }

    items.sort(
      (ConsultationItem a, ConsultationItem b) =>
          b.consultationDateTime.compareTo(a.consultationDateTime),
    );

    return items;
  }

  static Future<void> saveItems(List<ConsultationItem> items) async {
    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      items.map((ConsultationItem item) => item.toJson()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar las consultas.');
    }
  }

  static Future<void> saveItem(ConsultationItem item) async {
    final List<ConsultationItem> items = loadItems();
    final int index = items.indexWhere(
      (ConsultationItem current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<ConsultationItem> items = loadItems()
      ..removeWhere((ConsultationItem item) => item.id == id);

    await saveItems(items);
  }
}
