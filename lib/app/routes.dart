import 'package:flutter/material.dart';

import '../features/allergies/screens/allergy_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/doctors/screens/doctor_screen.dart';
import '../features/family/screens/family_screen.dart';
import '../features/family/screens/family_selector_screen.dart';
import '../features/medical_history/screens/medical_history_screen.dart';
import '../features/medications/screens/medication_screen.dart';
import '../features/profile/screens/profile_screen.dart';
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

  static Map<String, WidgetBuilder> get routes {
    return <String, WidgetBuilder>{
      familySelector: (BuildContext context) => const FamilySelectorScreen(),
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
    };
  }
}
