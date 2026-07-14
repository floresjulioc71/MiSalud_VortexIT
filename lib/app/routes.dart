import 'package:flutter/material.dart';

import '../features/dashboard/screens/dashboard_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';

  static Map<String, WidgetBuilder> get routes {
    return {dashboard: (BuildContext context) => const DashboardScreen()};
  }
}
