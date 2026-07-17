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
    final p = _preferences;
    if (p == null) return <ClinicalDocument>[];
    final raw = p.getStringList(_storageKey(p)) ?? <String>[];
    final items = <ClinicalDocument>[];
    for (final value in raw) {
      try {
        items.add(ClinicalDocument.fromJson(value));
      } on Object {}
    }
    items.sort(_sortItems);
    return List<ClinicalDocument>.unmodifiable(items);
  }

  static Future<void> saveItem(ClinicalDocument item) async {
    await initialize();
    final p = _preferences!;
    final key = _storageKey(p);
    final items = _readItems(p, key);
    final index = items.indexWhere((e) => e.id == item.id);
    final normalized = item.copyWith(
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
    await p.setStringList(key, items.map((e) => e.toJson()).toList());
  }

  static Future<void> deleteItem(String id) async {
    await initialize();
    final p = _preferences!;
    final key = _storageKey(p);
    final items = _readItems(p, key)..removeWhere((e) => e.id == id);
    await p.setStringList(key, items.map((e) => e.toJson()).toList());
  }

  static Future<void> clear() async {
    await initialize();
    final p = _preferences!;
    await p.remove(_storageKey(p));
  }

  static List<ClinicalDocument> _readItems(SharedPreferences p, String key) {
    final items = <ClinicalDocument>[];
    for (final raw in p.getStringList(key) ?? <String>[]) {
      try {
        items.add(ClinicalDocument.fromJson(raw));
      } on Object {}
    }
    return items;
  }

  static String _storageKey(SharedPreferences p) =>
      '${_baseKey}_${_memberScope(p)}';
  static String _memberScope(SharedPreferences p) {
    for (final key in _memberKeys) {
      final value = p.get(key);
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is int) return value.toString();
    }
    return 'default';
  }

  static int _sortItems(ClinicalDocument a, ClinicalDocument b) {
    final c = b.documentDate.compareTo(a.documentDate);
    return c != 0 ? c : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
