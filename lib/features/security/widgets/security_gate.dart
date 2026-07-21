import 'package:flutter/material.dart';

import '../../family/screens/family_selector_screen.dart';
import '../screens/unlock_screen.dart';
import '../services/security_service.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  bool _isUnlocked = false;

  bool get _requiresPin {
    return SecurityService.hasPin();
  }

  void _handleUnlocked() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_requiresPin || _isUnlocked) {
      return const FamilySelectorScreen();
    }

    return UnlockScreen(canClose: false, onUnlocked: _handleUnlocked);
  }
}
