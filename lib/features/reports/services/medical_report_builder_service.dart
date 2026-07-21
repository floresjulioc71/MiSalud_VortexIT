import '../../allergies/models/allergy_item.dart';
import '../../allergies/services/allergy_storage_service.dart';
import '../../clinical_documents/models/clinical_document.dart';
import '../../clinical_documents/services/clinical_document_storage_service.dart';
import '../../consultations/models/consultation_item.dart';
import '../../consultations/services/consultation_storage_service.dart';
import '../../doctors/models/doctor_item.dart';
import '../../doctors/services/doctor_storage_service.dart';
import '../../health_controls/models/health_control.dart';
import '../../health_controls/services/health_control_storage_service.dart';
import '../../medical_history/models/medical_history_item.dart';
import '../../medical_history/services/medical_history_storage_service.dart';
import '../../medical_studies/models/medical_study.dart';
import '../../medical_studies/services/medical_study_storage_service.dart';
import '../../medications/models/medication_item.dart';
import '../../medications/services/medication_storage_service.dart';
import '../../profile/models/medical_profile.dart';
import '../../profile/services/medical_profile_storage_service.dart';
import '../../surgeries/models/surgery_item.dart';
import '../../surgeries/services/surgery_storage_service.dart';
import '../../vaccines/models/vaccine_item.dart';
import '../../vaccines/services/vaccine_storage_service.dart';
import '../models/medical_report_data.dart';
import 'report_mapper_service.dart';

class MedicalReportBuilderService {
  const MedicalReportBuilderService._();

  static Future<MedicalReportData> build({
    required String familyMemberId,
    required String patientName,
  }) async {
    final MedicalProfile profile = MedicalProfileStorageService.loadProfile();

    final List<MedicalHistoryItem> medicalHistory =
        MedicalHistoryStorageService.loadItems();

    final List<AllergyItem> allergies = AllergyStorageService.loadItems();

    final List<MedicationItem> medications =
        MedicationStorageService.loadItems();

    final List<VaccineItem> vaccines = VaccineStorageService.loadItems();

    final List<SurgeryItem> surgeries = SurgeryStorageService.loadItems();

    final List<MedicalStudy> medicalStudies =
        await MedicalStudyStorageService.loadItems();

    final List<ClinicalDocument> clinicalDocuments =
        ClinicalDocumentStorageService.loadItems();

    final List<DoctorItem> doctors = DoctorStorageService.loadItems();

    final List<ConsultationItem> consultations =
        ConsultationStorageService.loadItems();

    final List<HealthControl> healthControls =
        HealthControlStorageService.loadItems();

    final String resolvedPatientName = profile.fullName.trim().isNotEmpty
        ? profile.fullName.trim()
        : patientName.trim();

    return MedicalReportData(
      familyMemberId: familyMemberId,
      patientName: resolvedPatientName,
      generatedAt: DateTime.now(),
      profile: profile.toMap(),
      medicalHistory: ReportMapperService.mapList(
        medicalHistory,
        (MedicalHistoryItem item) => item.toMap(),
      ),
      allergies: ReportMapperService.mapList(
        allergies,
        (AllergyItem item) => item.toMap(),
      ),
      medications: ReportMapperService.mapList(
        medications,
        (MedicationItem item) => item.toMap(),
      ),
      vaccines: ReportMapperService.mapList(
        vaccines,
        (VaccineItem item) => item.toMap(),
      ),
      surgeries: ReportMapperService.mapList(
        surgeries,
        (SurgeryItem item) => item.toMap(),
      ),
      medicalStudies: ReportMapperService.mapList(
        medicalStudies,
        (MedicalStudy item) => item.toJson(),
      ),
      clinicalDocuments: ReportMapperService.mapList(
        clinicalDocuments,
        (ClinicalDocument item) => item.toMap(),
      ),
      doctors: ReportMapperService.mapList(
        doctors,
        (DoctorItem item) => item.toMap(),
      ),
      consultations: ReportMapperService.mapList(
        consultations,
        (ConsultationItem item) => item.toMap(),
      ),
      healthControls: ReportMapperService.mapList(
        healthControls,
        (HealthControl item) => item.toJson(),
      ),
    );
  }
}
