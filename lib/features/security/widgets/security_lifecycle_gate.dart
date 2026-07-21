import 'package:flutter/material.dart';

import '../screens/unlock_screen.dart';
import '../services/security_service.dart';

class SecurityLifecycleGate extends StatefulWidget {
  final Widget child;

  const SecurityLifecycleGate({super.key, required this.child});

  @override
  State<SecurityLifecycleGate> createState() => _SecurityLifecycleGateState();
}

class _SecurityLifecycleGateState extends State<SecurityLifecycleGate>
    with WidgetsBindingObserver {
  static const Duration _gracePeriod = Duration(seconds: 30);

  bool _mustUnlock = false;
  DateTime? _backgroundStartedAt;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _registerBackgroundStart();
        break;

      case AppLifecycleState.resumed:
        _evaluateLockAfterResume();
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  void _registerBackgroundStart() {
    _backgroundStartedAt ??= DateTime.now();
  }

  void _evaluateLockAfterResume() {
    final DateTime? backgroundStartedAt = _backgroundStartedAt;

    _backgroundStartedAt = null;

    if (backgroundStartedAt == null) {
      return;
    }

    if (!SecurityService.hasPin()) {
      return;
    }

    final Duration elapsed = DateTime.now().difference(backgroundStartedAt);

    if (elapsed < _gracePeriod) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _mustUnlock = true;
    });
  }

  void _handleUnlocked() {
    if (!mounted) {
      return;
    }

    setState(() {
      _mustUnlock = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        if (_mustUnlock)
          Positioned.fill(
            child: Material(
              child: UnlockScreen(canClose: false, onUnlocked: _handleUnlocked),
            ),
          ),
      ],
    );
  }
}
