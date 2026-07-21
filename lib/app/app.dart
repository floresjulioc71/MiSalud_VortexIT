import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/navigation_service.dart';
import '../features/security/widgets/security_lifecycle_gate.dart';
import 'routes.dart';
import 'theme.dart';

class MiSaludApp extends StatelessWidget {
  const MiSaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.familySelector,
      routes: AppRoutes.routes,
      builder: (BuildContext context, Widget? child) {
        return SecurityLifecycleGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
