import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vaccine_item.dart';

class VaccineStorageService {
  static const String _storageKey = 'vaccines';
  static List<VaccineItem> _items = <VaccineItem>[];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> rawItems =
        preferences.getStringList(_storageKey) ?? <String>[];

    _items = rawItems.map(VaccineItem.fromJson).toList()..sort(_sortItems);

    _initialized = true;
  }

  static List<VaccineItem> loadItems() {
    return List<VaccineItem>.unmodifiable(_items);
  }

  static Future<void> saveItem(VaccineItem item) async {
    await initialize();

    final int index = _items.indexWhere(
      (VaccineItem current) => current.id == item.id,
    );

    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }

    _items.sort(_sortItems);
    await _persist();
  }

  static Future<void> deleteItem(String id) async {
    await initialize();
    _items.removeWhere((VaccineItem item) => item.id == id);
    await _persist();
  }

  static Future<void> clear() async {
    await initialize();
    _items.clear();
    await _persist();
  }

  static Future<void> _persist() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      _items.map((VaccineItem item) => item.toJson()).toList(),
    );
  }

  static int _sortItems(VaccineItem a, VaccineItem b) {
    final DateTime aDate =
        a.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bDate =
        b.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }
}
