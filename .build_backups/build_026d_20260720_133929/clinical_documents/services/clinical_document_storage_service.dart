import 'package:shared_preferences/shared_preferences.dart';

import '../models/clinical_document.dart';

class ClinicalDocumentStorageService {
  static const String _baseKey = 'clinical_documents_v1';

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

  static List<ClinicalDocument> loadItems() {
    final SharedPreferences? preferences = _preferences;

    if (preferences == null) {
      return <ClinicalDocument>[];
    }

    return List<ClinicalDocument>.unmodifiable(
      _readItems(preferences, _storageKey(preferences))..sort(_sortItems),
    );
  }

  static Future<void> saveItem(ClinicalDocument item) async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    final String key = _storageKey(preferences);
    final List<ClinicalDocument> items = _readItems(preferences, key);

    final int index = items.indexWhere(
      (ClinicalDocument current) => current.id == item.id,
    );

    final ClinicalDocument normalized = item.copyWith(
      title: item.title.trim(),
      professional: item.professional.trim(),
      institution: item.institution.trim(),
      notes: item.notes.trim(),
      fileName: item.fileName.trim(),
      filePath: item.filePath.trim(),
      mimeType: item.mimeType.trim(),
      updatedAt: DateTime.now(),
    );

    if (index >= 0) {
      items[index] = normalized;
    } else {
      items.add(normalized);
    }

    items.sort(_sortItems);

    await preferences.setStringList(
      key,
      items.map((ClinicalDocument value) => value.toJson()).toList(),
    );
  }

  static Future<void> deleteItem(String id) async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    final String key = _storageKey(preferences);
    final List<ClinicalDocument> items = _readItems(preferences, key)
      ..removeWhere((ClinicalDocument item) => item.id == id);

    await preferences.setStringList(
      key,
      items.map((ClinicalDocument value) => value.toJson()).toList(),
    );
  }

  static Future<void> clear() async {
    await initialize();

    final SharedPreferences preferences = _preferences!;
    await preferences.remove(_storageKey(preferences));
  }

  static List<ClinicalDocument> _readItems(
    SharedPreferences preferences,
    String key,
  ) {
    final List<String> rawItems = preferences.getStringList(key) ?? <String>[];
    final List<ClinicalDocument> items = <ClinicalDocument>[];

    for (final String raw in rawItems) {
      try {
        items.add(ClinicalDocument.fromJson(raw));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
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

  static int _sortItems(ClinicalDocument a, ClinicalDocument b) {
    final int dateComparison = b.documentDate.compareTo(a.documentDate);

    if (dateComparison != 0) {
      return dateComparison;
    }

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
