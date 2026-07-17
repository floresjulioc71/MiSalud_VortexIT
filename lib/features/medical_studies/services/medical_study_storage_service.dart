import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/medical_study.dart';

class MedicalStudyStorageService {
  static const String _baseKey = 'medical_studies_v1';

  static Future<String> _scope() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    const List<String> candidateKeys = <String>[
      'selected_family_member_id',
      'selectedFamilyMemberId',
      'active_family_member_id',
      'current_family_member_id',
      'selected_member_id',
    ];
    for (final String key in candidateKeys) {
      final String? value = preferences.getString(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'default';
  }

  static Future<String> _key() async => '${_baseKey}_${await _scope()}';

  static Future<List<MedicalStudy>> loadItems() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(await _key());
    if (raw == null || raw.isEmpty) {
      return <MedicalStudy>[];
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <MedicalStudy>[];
      }
      final List<MedicalStudy> items = decoded
          .whereType<Map>()
          .map(
            (Map item) =>
                MedicalStudy.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      items.sort(
        (MedicalStudy a, MedicalStudy b) => b.studyDate.compareTo(a.studyDate),
      );
      return items;
    } on Object {
      return <MedicalStudy>[];
    }
  }

  static Future<void> saveItems(List<MedicalStudy> items) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      await _key(),
      jsonEncode(items.map((MedicalStudy item) => item.toJson()).toList()),
    );
  }

  static Future<void> upsert(MedicalStudy item) async {
    final List<MedicalStudy> items = await loadItems();
    final int index = items.indexWhere(
      (MedicalStudy current) => current.id == item.id,
    );
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    items.sort(
      (MedicalStudy a, MedicalStudy b) => b.studyDate.compareTo(a.studyDate),
    );
    await saveItems(items);
  }

  static Future<void> delete(String id) async {
    final List<MedicalStudy> items = await loadItems();
    items.removeWhere((MedicalStudy item) => item.id == id);
    await saveItems(items);
  }
}
