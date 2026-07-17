import '../../../core/storage/app_storage.dart';
import '../../family/services/family_storage_service.dart';
import '../models/health_control.dart';

class HealthControlStorageService {
  HealthControlStorageService._();

  static const String _baseStorageKey = 'health_controls';

  static String get _storageKey =>
      FamilyStorageService.scopedKey(_baseStorageKey);

  static List<HealthControl> loadItems() {
    final List<String>? storedItems = AppStorage.readStringList(_storageKey);

    if (storedItems == null || storedItems.isEmpty) {
      return <HealthControl>[];
    }

    final List<HealthControl> items = <HealthControl>[];

    for (final String source in storedItems) {
      try {
        items.add(HealthControl.fromJsonString(source));
      } on FormatException {
        continue;
      }
    }

    items.sort(
      (HealthControl a, HealthControl b) =>
          b.recordedAt.compareTo(a.recordedAt),
    );

    return items;
  }

  static Future<void> saveItems(List<HealthControl> items) async {
    final List<HealthControl> ordered = List<HealthControl>.from(items)
      ..sort(
        (HealthControl a, HealthControl b) =>
            b.recordedAt.compareTo(a.recordedAt),
      );

    final bool saved = await AppStorage.saveStringList(
      _storageKey,
      ordered.map((HealthControl item) => item.toJsonString()).toList(),
    );

    if (!saved) {
      throw StateError('No fue posible guardar los controles de salud.');
    }
  }

  static Future<void> saveItem(HealthControl item) async {
    final List<HealthControl> items = loadItems();
    final int index = items.indexWhere(
      (HealthControl current) => current.id == item.id,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await saveItems(items);
  }

  static Future<void> deleteItem(String id) async {
    final List<HealthControl> items = loadItems()
      ..removeWhere((HealthControl item) => item.id == id);

    await saveItems(items);
  }
}
