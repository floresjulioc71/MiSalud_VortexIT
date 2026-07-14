import 'package:flutter/material.dart';

import '../features/dashboard/screens/dashboard_screen.dart';
import 'theme.dart';

class MiSaludApp extends StatelessWidget {
  const MiSaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiSalud VortexIT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
    );
  }
}
