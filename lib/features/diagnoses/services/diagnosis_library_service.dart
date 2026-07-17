import 'package:shared_preferences/shared_preferences.dart';

import '../models/diagnosis_library_item.dart';

class DiagnosisLibraryService {
  const DiagnosisLibraryService._();

  static const String _storageKey = 'global_diagnosis_library_v1';

  static Future<List<DiagnosisLibraryItem>> loadItems() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final List<String> stored =
        preferences.getStringList(_storageKey) ?? <String>[];

    final List<DiagnosisLibraryItem> items = <DiagnosisLibraryItem>[];

    for (final String value in stored) {
      try {
        final DiagnosisLibraryItem item = DiagnosisLibraryItem.fromJson(value);

        if (item.description.trim().isNotEmpty) {
          items.add(item);
        }
      } on Object {
        // Ignora únicamente registros dañados.
      }
    }

    items.sort(_compareItems);
    return items;
  }

  static Future<void> saveItems(List<DiagnosisLibraryItem> items) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final List<DiagnosisLibraryItem> cleanItems = _deduplicate(items)
      ..sort(_compareItems);

    await preferences.setStringList(
      _storageKey,
      cleanItems.map((DiagnosisLibraryItem item) => item.toJson()).toList(),
    );
  }

  static Future<DiagnosisLibraryItem> registerDescription(
    String description, {
    bool incrementUse = true,
  }) async {
    final String cleanDescription = description.trim();
    final String normalized = DiagnosisLibraryItem.normalize(cleanDescription);
    final List<DiagnosisLibraryItem> items = await loadItems();
    final DateTime now = DateTime.now();

    final int index = items.indexWhere(
      (DiagnosisLibraryItem item) => item.normalizedDescription == normalized,
    );

    late final DiagnosisLibraryItem result;

    if (index >= 0) {
      final DiagnosisLibraryItem current = items[index];
      result = current.copyWith(
        description: cleanDescription,
        normalizedDescription: normalized,
        useCount: incrementUse ? current.useCount + 1 : current.useCount,
        updatedAt: now,
      );
      items[index] = result;
    } else {
      result = DiagnosisLibraryItem(
        id: now.microsecondsSinceEpoch.toString(),
        description: cleanDescription,
        normalizedDescription: normalized,
        useCount: incrementUse ? 1 : 0,
        createdAt: now,
        updatedAt: now,
      );
      items.add(result);
    }

    await saveItems(items);
    return result;
  }

  static Future<DiagnosisLibraryItem> addOrIncrement(String description) {
    return registerDescription(description);
  }

  static Future<void> registerDescriptions(
    Iterable<String> descriptions, {
    bool incrementUse = true,
  }) async {
    final List<DiagnosisLibraryItem> items = await loadItems();
    final Map<String, DiagnosisLibraryItem> indexed =
        <String, DiagnosisLibraryItem>{
          for (final DiagnosisLibraryItem item in items)
            item.normalizedDescription: item,
        };
    final DateTime now = DateTime.now();

    for (final String rawDescription in descriptions) {
      final String description = rawDescription.trim();

      if (description.isEmpty) {
        continue;
      }

      final String normalized = DiagnosisLibraryItem.normalize(description);
      final DiagnosisLibraryItem? current = indexed[normalized];

      if (current == null) {
        indexed[normalized] = DiagnosisLibraryItem(
          id: '${now.microsecondsSinceEpoch}_${indexed.length}',
          description: description,
          normalizedDescription: normalized,
          useCount: incrementUse ? 1 : 0,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        indexed[normalized] = current.copyWith(
          description: description,
          useCount: incrementUse ? current.useCount + 1 : current.useCount,
          updatedAt: now,
        );
      }
    }

    await saveItems(indexed.values.toList());
  }

  static Future<bool> renameItem(String id, String newDescription) async {
    final String cleanDescription = newDescription.trim();

    if (cleanDescription.isEmpty) {
      return false;
    }

    final String normalized = DiagnosisLibraryItem.normalize(cleanDescription);
    final List<DiagnosisLibraryItem> items = await loadItems();

    final bool duplicate = items.any(
      (DiagnosisLibraryItem item) =>
          item.id != id && item.normalizedDescription == normalized,
    );

    if (duplicate) {
      return false;
    }

    final int index = items.indexWhere(
      (DiagnosisLibraryItem item) => item.id == id,
    );

    if (index < 0) {
      return false;
    }

    items[index] = items[index].copyWith(
      description: cleanDescription,
      normalizedDescription: normalized,
      updatedAt: DateTime.now(),
    );

    await saveItems(items);
    return true;
  }

  static Future<bool> deleteItem(String id) async {
    final List<DiagnosisLibraryItem> items = await loadItems();
    final int originalLength = items.length;

    items.removeWhere((DiagnosisLibraryItem item) => item.id == id);

    if (items.length == originalLength) {
      return false;
    }

    await saveItems(items);
    return true;
  }

  static List<DiagnosisLibraryItem> search(
    List<DiagnosisLibraryItem> items,
    String query,
  ) {
    final String normalizedQuery = DiagnosisLibraryItem.normalize(query);

    if (normalizedQuery.isEmpty) {
      final List<DiagnosisLibraryItem> result = List<DiagnosisLibraryItem>.from(
        items,
      );
      result.sort(_compareItems);
      return result;
    }

    final List<DiagnosisLibraryItem> startsWith = <DiagnosisLibraryItem>[];
    final List<DiagnosisLibraryItem> contains = <DiagnosisLibraryItem>[];

    for (final DiagnosisLibraryItem item in items) {
      if (item.normalizedDescription.startsWith(normalizedQuery)) {
        startsWith.add(item);
      } else if (item.normalizedDescription.contains(normalizedQuery)) {
        contains.add(item);
      }
    }

    startsWith.sort(_compareItems);
    contains.sort(_compareItems);

    return <DiagnosisLibraryItem>[...startsWith, ...contains];
  }

  static bool containsDescription(
    List<DiagnosisLibraryItem> items,
    String description,
  ) {
    final String normalized = DiagnosisLibraryItem.normalize(description);

    return items.any(
      (DiagnosisLibraryItem item) => item.normalizedDescription == normalized,
    );
  }

  static List<DiagnosisLibraryItem> _deduplicate(
    Iterable<DiagnosisLibraryItem> items,
  ) {
    final Map<String, DiagnosisLibraryItem> unique =
        <String, DiagnosisLibraryItem>{};

    for (final DiagnosisLibraryItem item in items) {
      final String key = item.normalizedDescription.isEmpty
          ? DiagnosisLibraryItem.normalize(item.description)
          : item.normalizedDescription;

      final DiagnosisLibraryItem? current = unique[key];

      if (current == null || item.updatedAt.isAfter(current.updatedAt)) {
        unique[key] = item;
      }
    }

    return unique.values.toList();
  }

  static int _compareItems(DiagnosisLibraryItem a, DiagnosisLibraryItem b) {
    final int countComparison = b.useCount.compareTo(a.useCount);

    if (countComparison != 0) {
      return countComparison;
    }

    return a.description.toLowerCase().compareTo(b.description.toLowerCase());
  }
}
