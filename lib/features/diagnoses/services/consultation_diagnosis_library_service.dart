import '../../consultations/services/consultation_storage_service.dart';
import '../models/diagnosis_entry.dart';
import '../models/diagnosis_library_item.dart';
import 'diagnosis_library_service.dart';

class ConsultationDiagnosisLibraryService {
  const ConsultationDiagnosisLibraryService._();

  static Future<List<DiagnosisLibraryItem>> loadItems() async {
    final List<DiagnosisLibraryItem> storedItems =
        await DiagnosisLibraryService.loadItems();

    final Set<String> storedDescriptions = storedItems
        .map((DiagnosisLibraryItem item) => item.normalizedDescription)
        .toSet();

    final List<String> missingDescriptions = <String>[];

    for (final consultation in ConsultationStorageService.loadItems()) {
      for (final DiagnosisEntry diagnosis in consultation.diagnoses) {
        final String description = diagnosis.description.trim();
        final String normalized = normalize(description);

        if (description.isNotEmpty &&
            !storedDescriptions.contains(normalized)) {
          storedDescriptions.add(normalized);
          missingDescriptions.add(description);
        }
      }
    }

    if (missingDescriptions.isNotEmpty) {
      await DiagnosisLibraryService.registerDescriptions(
        missingDescriptions,
        incrementUse: false,
      );
    }

    return DiagnosisLibraryService.loadItems();
  }

  static Future<void> registerDiagnoses(List<DiagnosisEntry> diagnoses) async {
    await DiagnosisLibraryService.registerDescriptions(
      diagnoses.map((DiagnosisEntry diagnosis) => diagnosis.description),
    );
  }

  static List<DiagnosisLibraryItem> search(
    List<DiagnosisLibraryItem> entries,
    String query,
  ) {
    return DiagnosisLibraryService.search(entries, query);
  }

  static bool containsDescription(
    List<DiagnosisLibraryItem> entries,
    String description,
  ) {
    return DiagnosisLibraryService.containsDescription(entries, description);
  }

  static DiagnosisEntry toDiagnosisEntry(DiagnosisLibraryItem item) {
    final DateTime now = DateTime.now();

    return DiagnosisEntry(
      id: item.id,
      primarySystem: DiagnosisSystem.freeText,
      primaryCode: '',
      description: item.description,
      icd10Code: '',
      snomedCtCode: '',
      icpc2Code: '',
      terminologyVersion: '',
      status: DiagnosisStatus.active,
      origin: DiagnosisOrigin.selfRecord,
      diagnosisDate: now,
      notes: '',
    );
  }

  static String normalize(String value) {
    return DiagnosisLibraryItem.normalize(value);
  }
}
