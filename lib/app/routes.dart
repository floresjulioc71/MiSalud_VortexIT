import 'package:flutter/material.dart';

import '../features/allergies/screens/allergy_screen.dart';
import '../features/backup/screens/backup_screen.dart';
import '../features/consultations/screens/consultation_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/doctors/screens/doctor_screen.dart';
import '../features/family/screens/family_screen.dart';
import '../features/medical_history/screens/medical_history_screen.dart';
import '../features/medications/screens/medication_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/security/screens/change_pin_screen.dart';
import '../features/security/screens/create_pin_screen.dart';
import '../features/security/screens/security_settings_screen.dart';
import '../features/security/screens/unlock_screen.dart';
import '../features/security/widgets/security_gate.dart';
import '../features/studies/screens/study_screen.dart';
import '../features/surgeries/screens/surgery_screen.dart';
import '../features/vaccines/screens/vaccine_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String familySelector = '/';
  static const String dashboard = '/dashboard';
  static const String family = '/family';
  static const String profile = '/profile';
  static const String medicalHistory = '/medical-history';
  static const String allergies = '/allergies';
  static const String medications = '/medications';
  static const String surgeries = '/surgeries';
  static const String vaccines = '/vaccines';
  static const String studies = '/studies';
  static const String doctors = '/doctors';
  static const String consultations = '/consultations';
  static const String backup = '/backup';

  static const String security = '/security/create-pin';
  static const String securitySettings = '/security/settings';
  static const String unlock = '/security/unlock';
  static const String changePin = '/security/change-pin';

  static Map<String, WidgetBuilder> get routes {
    return <String, WidgetBuilder>{
      familySelector: (BuildContext context) => const SecurityGate(),
      dashboard: (BuildContext context) => const DashboardScreen(),
      family: (BuildContext context) => const FamilyScreen(),
      profile: (BuildContext context) => const ProfileScreen(),
      medicalHistory: (BuildContext context) => const MedicalHistoryScreen(),
      allergies: (BuildContext context) => const AllergyScreen(),
      medications: (BuildContext context) => const MedicationScreen(),
      surgeries: (BuildContext context) => const SurgeryScreen(),
      vaccines: (BuildContext context) => const VaccineScreen(),
      studies: (BuildContext context) => const StudyScreen(),
      doctors: (BuildContext context) => const DoctorScreen(),
      consultations: (BuildContext context) => const ConsultationScreen(),
      backup: (BuildContext context) => const BackupScreen(),
      security: (BuildContext context) => const CreatePinScreen(),
      securitySettings: (BuildContext context) =>
          const SecuritySettingsScreen(),
      unlock: (BuildContext context) => const UnlockScreen(canClose: true),
      changePin: (BuildContext context) => const ChangePinScreen(),
    };
  }
}
