class MedicalReportData {
  final String familyMemberId;
  final String patientName;
  final DateTime generatedAt;

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> medicalHistory;
  final List<Map<String, dynamic>> allergies;
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> vaccines;
  final List<Map<String, dynamic>> surgeries;
  final List<Map<String, dynamic>> medicalStudies;
  final List<Map<String, dynamic>> clinicalDocuments;
  final List<Map<String, dynamic>> doctors;
  final List<Map<String, dynamic>> consultations;
  final List<Map<String, dynamic>> healthControls;

  const MedicalReportData({
    required this.familyMemberId,
    required this.patientName,
    required this.generatedAt,
    required this.profile,
    required this.medicalHistory,
    required this.allergies,
    required this.medications,
    required this.vaccines,
    required this.surgeries,
    required this.medicalStudies,
    required this.clinicalDocuments,
    required this.doctors,
    required this.consultations,
    required this.healthControls,
  });

  bool get hasProfile => profile.isNotEmpty;

  bool get hasMedicalHistory => medicalHistory.isNotEmpty;

  bool get hasAllergies => allergies.isNotEmpty;

  bool get hasMedications => medications.isNotEmpty;

  bool get hasVaccines => vaccines.isNotEmpty;

  bool get hasSurgeries => surgeries.isNotEmpty;

  bool get hasMedicalStudies => medicalStudies.isNotEmpty;

  bool get hasClinicalDocuments => clinicalDocuments.isNotEmpty;

  bool get hasDoctors => doctors.isNotEmpty;

  bool get hasConsultations => consultations.isNotEmpty;

  bool get hasHealthControls => healthControls.isNotEmpty;

  bool get hasAnyClinicalInformation =>
      hasProfile ||
      hasMedicalHistory ||
      hasAllergies ||
      hasMedications ||
      hasVaccines ||
      hasSurgeries ||
      hasMedicalStudies ||
      hasClinicalDocuments ||
      hasDoctors ||
      hasConsultations ||
      hasHealthControls;
}
