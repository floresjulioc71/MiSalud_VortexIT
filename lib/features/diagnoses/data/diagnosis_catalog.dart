import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/diagnosis_entry.dart';

class DiagnosisCatalog {
  DiagnosisCatalog._();

  static const String assetPath = 'assets/data/icd11_es_2026_01.json';

  static List<DiagnosisEntry>? _cachedEntries;

  static Future<List<DiagnosisEntry>> load() async {
    if (_cachedEntries != null) {
      return _cachedEntries!;
    }

    final String source = await rootBundle.loadString(assetPath);
    final dynamic decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El catálogo CIE-11 tiene un formato inválido.',
      );
    }

    final dynamic rawEntries = decoded['entries'];

    if (rawEntries is! List<dynamic>) {
      throw const FormatException(
        'El catálogo CIE-11 no contiene diagnósticos.',
      );
    }

    final List<DiagnosisEntry> entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(DiagnosisEntry.fromMap)
        .where((DiagnosisEntry entry) => entry.description.trim().isNotEmpty)
        .toList();

    entries.sort(
      (DiagnosisEntry a, DiagnosisEntry b) =>
          a.primaryCode.compareTo(b.primaryCode),
    );

    _cachedEntries = List<DiagnosisEntry>.unmodifiable(entries);
    return _cachedEntries!;
  }

  static List<DiagnosisEntry> search(
    List<DiagnosisEntry> entries,
    String query, {
    int limit = 100,
  }) {
    final String normalized = _normalize(query);

    if (normalized.isEmpty) {
      return entries.take(limit).toList();
    }

    final List<_ScoredDiagnosis> matches = <_ScoredDiagnosis>[];

    for (final DiagnosisEntry entry in entries) {
      final String code = _normalize(entry.primaryCode);
      final String description = _normalize(entry.description);
      final String icd10 = _normalize(entry.icd10Code);
      final String snomed = _normalize(entry.snomedCtCode);
      final String icpc2 = _normalize(entry.icpc2Code);

      int score = 0;

      if (code == normalized) {
        score = 100;
      } else if (code.startsWith(normalized)) {
        score = 90;
      } else if (description == normalized) {
        score = 80;
      } else if (description.startsWith(normalized)) {
        score = 70;
      } else if (description.contains(normalized)) {
        score = 60;
      } else if (code.contains(normalized) ||
          icd10.contains(normalized) ||
          snomed.contains(normalized) ||
          icpc2.contains(normalized)) {
        score = 50;
      }

      if (score > 0) {
        matches.add(_ScoredDiagnosis(entry: entry, score: score));
      }
    }

    matches.sort((_ScoredDiagnosis a, _ScoredDiagnosis b) {
      final int scoreComparison = b.score.compareTo(a.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.entry.description.compareTo(b.entry.description);
    });

    return matches
        .take(limit)
        .map((_ScoredDiagnosis match) => match.entry)
        .toList();
  }

  static String _normalize(String value) {
    const Map<String, String> replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };

    String result = value.trim().toLowerCase();

    replacements.forEach((String key, String replacement) {
      result = result.replaceAll(key, replacement);
    });

    return result;
  }
}

class _ScoredDiagnosis {
  final DiagnosisEntry entry;
  final int score;

  const _ScoredDiagnosis({required this.entry, required this.score});
}
