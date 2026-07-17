import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vaccine_record.dart';

class VaccineStorageService {
  static const String _baseKey = 'vaccines_v1';

  static Future<String> _scope() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    const List<String> keys = <String>[
      'selected_family_member_id',
      'selectedFamilyMemberId',
      'active_family_member_id',
      'current_family_member_id',
      'selected_member_id',
    ];
    for (final String key in keys) {
      final String? value = preferences.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'default';
  }

  static Future<String> _key() async => '${_baseKey}_${await _scope()}';

  static Future<List<VaccineRecord>> loadItems() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(await _key());
    if (raw == null || raw.isEmpty) {
      return <VaccineRecord>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <VaccineRecord>[];
      }
      final List<VaccineRecord> items = decoded
          .whereType<Map>()
          .map(
            (Map item) =>
                VaccineRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      items.sort(
        (VaccineRecord a, VaccineRecord b) =>
            b.applicationDate.compareTo(a.applicationDate),
      );
      return items;
    } on Object {
      return <VaccineRecord>[];
    }
  }

  static Future<void> saveItems(List<VaccineRecord> items) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      await _key(),
      jsonEncode(items.map((VaccineRecord item) => item.toJson()).toList()),
    );
  }

  static Future<void> upsert(VaccineRecord item) async {
    final List<VaccineRecord> items = await loadItems();
    final int index = items.indexWhere(
      (VaccineRecord current) => current.id == item.id,
    );
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    items.sort(
      (VaccineRecord a, VaccineRecord b) =>
          b.applicationDate.compareTo(a.applicationDate),
    );
    await saveItems(items);
  }

  static Future<void> delete(String id) async {
    final List<VaccineRecord> items = await loadItems();
    items.removeWhere((VaccineRecord item) => item.id == id);
    await saveItems(items);
  }
}
