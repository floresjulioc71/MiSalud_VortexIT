import 'package:shared_preferences/shared_preferences.dart';

import '../models/vaccine_item.dart';

class VaccineStorageService {
  static const String _baseKey = 'vaccines';

  static SharedPreferences? _preferences;

  static const List<String> _memberKeys = <String>[
    'selected_family_member_id',
    'selectedFamilyMemberId',
    'active_family_member_id',
    'activeFamilyMemberId',
    'current_family_member_id',
    'currentFamilyMemberId',
    'selected_member_id',
    'selectedMemberId',
    'selected_profile_id',
    'selectedProfileId',
    'active_profile_id',
    'activeProfileId',
    'current_profile_id',
    'currentProfileId',
    'medical_profile_active_id',
  ];

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static List<VaccineItem> loadItems() {
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) {
      return <VaccineItem>[];
    }

    final List<String> rawItems =
        preferences.getStringList(_storageKey(preferences)) ?? <String>[];

    final List<VaccineItem> items = <VaccineItem>[];

    for (final String raw in rawItems) {
      try {
        items.add(VaccineItem.fromJson(raw));
      } on Object {
        // Ignora solamente registros dañados y conserva el resto.
      }
    }

    items.sort(_sortItems);
    return List<VaccineItem>.unmodifiable(items);
  }

  static Future<void> saveItem(VaccineItem item) async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    final String key = _storageKey(preferences);
    final List<VaccineItem> items = _readItems(preferences, key);

    final int index = items.indexWhere(
      (VaccineItem current) => current.id == item.id,
    );

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    items.sort(_sortItems);

    await preferences.setStringList(
      key,
      items.map((VaccineItem value) => value.toJson()).toList(),
    );
  }

  static Future<void> deleteItem(String id) async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    final String key = _storageKey(preferences);
    final List<VaccineItem> items = _readItems(preferences, key)
      ..removeWhere((VaccineItem item) => item.id == id);

    await preferences.setStringList(
      key,
      items.map((VaccineItem value) => value.toJson()).toList(),
    );
  }

  static Future<void> clear() async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    await preferences.remove(_storageKey(preferences));
  }

  static List<VaccineItem> _readItems(
    SharedPreferences preferences,
    String key,
  ) {
    final List<String> rawItems = preferences.getStringList(key) ?? <String>[];

    final List<VaccineItem> items = <VaccineItem>[];

    for (final String raw in rawItems) {
      try {
        items.add(VaccineItem.fromJson(raw));
      } on Object {
        // Ignora solamente registros dañados y conserva el resto.
      }
    }

    return items;
  }

  static String _storageKey(SharedPreferences preferences) {
    return '${_baseKey}_${_memberScope(preferences)}';
  }

  static String _memberScope(SharedPreferences preferences) {
    for (final String key in _memberKeys) {
      final Object? value = preferences.get(key);

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is int) {
        return value.toString();
      }
    }

    return 'default';
  }

  static int _sortItems(VaccineItem a, VaccineItem b) {
    final DateTime aDate =
        a.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bDate =
        b.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);

    return bDate.compareTo(aDate);
  }
}
