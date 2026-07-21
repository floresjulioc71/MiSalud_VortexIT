import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../widgets/pin_indicator.dart';
import '../widgets/pin_keyboard.dart';

class UnlockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool canClose;

  const UnlockScreen({super.key, this.onUnlocked, this.canClose = false});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  static const int _pinLength = 4;

  String _enteredPin = '';
  String? _errorMessage;

  bool _isChecking = false;

  void _addDigit(String digit) {
    if (_isChecking || _enteredPin.length >= _pinLength) {
      return;
    }

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == _pinLength) {
      Future<void>.delayed(const Duration(milliseconds: 180), _verifyPin);
    }
  }

  void _removeLastDigit() {
    if (_isChecking || _enteredPin.isEmpty) {
      return;
    }

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    if (_enteredPin.length != _pinLength || _isChecking) {
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final bool authenticated = await SecurityService.authenticate(_enteredPin);

    if (!mounted) {
      return;
    }

    if (authenticated) {
      final VoidCallback? callback = widget.onUnlocked;

      if (callback != null) {
        callback();
      } else {
        Navigator.of(context).pop(true);
      }

      return;
    }

    final int remainingAttempts = SecurityService.remainingAttempts();

    setState(() {
      _enteredPin = '';
      _isChecking = false;

      if (remainingAttempts > 0) {
        _errorMessage = 'PIN incorrecto. Quedan $remainingAttempts intentos.';
      } else {
        _errorMessage = 'Se alcanzó el máximo de intentos incorrectos.';
      }
    });
  }

  Future<bool> _handleBackNavigation() async {
    return widget.canClose;
  }

  @override
  Widget build(BuildContext context) {
    final bool maximumAttemptsReached =
        SecurityService.hasReachedMaximumAttempts();

    return PopScope(
      canPop: widget.canClose,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: widget.canClose,
          title: const Text('Desbloquear MiSalud'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.lock_outline,
                        size: 44,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aplicación protegida',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ingresá tu PIN de 4 dígitos para acceder '
                      'a la información médica.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 30),
                    PinIndicator(
                      enteredDigits: _enteredPin.length,
                      totalDigits: _pinLength,
                      hasError: _errorMessage != null,
                    ),
                    SizedBox(
                      height: 70,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Text(
                                  _errorMessage!,
                                  key: ValueKey<String>(_errorMessage!),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    PinKeyboard(
                      enabled: !_isChecking && !maximumAttemptsReached,
                      onDigitPressed: _addDigit,
                      onBackspacePressed: _removeLastDigit,
                    ),
                    const SizedBox(height: 20),
                    if (_isChecking)
                      const Column(
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Verificando PIN...'),
                        ],
                      ),
                    if (maximumAttemptsReached)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'El acceso está temporalmente '
                                  'bloqueado por seguridad.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
