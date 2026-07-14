import 'package:flutter/material.dart';

import '../features/allergies/screens/allergy_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/medical_history/screens/medical_history_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String profile = '/profile';
  static const String medicalHistory = '/medical-history';
  static const String allergies = '/allergies';

  static Map<String, WidgetBuilder> get routes {
    return <String, WidgetBuilder>{
      dashboard: (BuildContext context) => const DashboardScreen(),
      profile: (BuildContext context) => const ProfileScreen(),
      medicalHistory: (BuildContext context) => const MedicalHistoryScreen(),
      allergies: (BuildContext context) => const AllergyScreen(),
    };
  }
}
