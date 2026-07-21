import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../widgets/pin_indicator.dart';
import '../widgets/pin_keyboard.dart';

enum _ChangePinStep { currentPin, newPin, confirmNewPin }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  static const int _pinLength = 4;

  _ChangePinStep _step = _ChangePinStep.currentPin;

  String _enteredPin = '';
  String _currentPin = '';
  String _newPin = '';
  String? _errorMessage;

  bool _isSaving = false;

  String get _title {
    switch (_step) {
      case _ChangePinStep.currentPin:
        return 'PIN actual';
      case _ChangePinStep.newPin:
        return 'Nuevo PIN';
      case _ChangePinStep.confirmNewPin:
        return 'Confirmar nuevo PIN';
    }
  }

  String get _description {
    switch (_step) {
      case _ChangePinStep.currentPin:
        return 'Ingresá el PIN actual para verificar tu identidad.';
      case _ChangePinStep.newPin:
        return 'Elegí un nuevo PIN de 4 dígitos.';
      case _ChangePinStep.confirmNewPin:
        return 'Ingresá nuevamente el nuevo PIN.';
    }
  }

  void _addDigit(String digit) {
    if (_isSaving || _enteredPin.length >= _pinLength) {
      return;
    }

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == _pinLength) {
      Future<void>.delayed(const Duration(milliseconds: 180), _processPin);
    }
  }

  void _removeLastDigit() {
    if (_isSaving || _enteredPin.isEmpty) {
      return;
    }

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _processPin() async {
    if (_enteredPin.length != _pinLength) {
      return;
    }

    switch (_step) {
      case _ChangePinStep.currentPin:
        await _validateCurrentPin();
        return;

      case _ChangePinStep.newPin:
        setState(() {
          _newPin = _enteredPin;
          _enteredPin = '';
          _step = _ChangePinStep.confirmNewPin;
          _errorMessage = null;
        });
        return;

      case _ChangePinStep.confirmNewPin:
        await _confirmAndSavePin();
        return;
    }
  }

  Future<void> _validateCurrentPin() async {
    final bool valid = await SecurityService.authenticate(_enteredPin);

    if (!mounted) {
      return;
    }

    if (!valid) {
      final int remaining = SecurityService.remainingAttempts();

      setState(() {
        _enteredPin = '';

        if (remaining > 0) {
          _errorMessage = 'PIN actual incorrecto. Quedan $remaining intentos.';
        } else {
          _errorMessage = 'Se alcanzó el máximo de intentos incorrectos.';
        }
      });

      return;
    }

    setState(() {
      _currentPin = _enteredPin;
      _enteredPin = '';
      _step = _ChangePinStep.newPin;
      _errorMessage = null;
    });
  }

  Future<void> _confirmAndSavePin() async {
    if (_enteredPin != _newPin) {
      setState(() {
        _enteredPin = '';
        _newPin = '';
        _step = _ChangePinStep.newPin;
        _errorMessage = 'Los nuevos PIN no coinciden. Intentá nuevamente.';
      });

      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await SecurityService.changePin(oldPin: _currentPin, newPin: _newPin);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN actualizado correctamente.')),
      );

      Navigator.of(context).pop(true);
    } on SecurityException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _enteredPin = '';
        _currentPin = '';
        _newPin = '';
        _step = _ChangePinStep.currentPin;
        _isSaving = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _enteredPin = '';
        _currentPin = '';
        _newPin = '';
        _step = _ChangePinStep.currentPin;
        _isSaving = false;
        _errorMessage = 'No se pudo cambiar el PIN. Intentá nuevamente.';
      });
    }
  }

  void _restart() {
    if (_isSaving) {
      return;
    }

    setState(() {
      _enteredPin = '';
      _currentPin = '';
      _newPin = '';
      _step = _ChangePinStep.currentPin;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool maximumAttemptsReached =
        SecurityService.hasReachedMaximumAttempts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar PIN'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Comenzar nuevamente',
            onPressed: _isSaving ? null : _restart,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                    radius: 42,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.password_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _description,
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
                      child: _errorMessage == null
                          ? const SizedBox.shrink()
                          : Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  PinKeyboard(
                    enabled: !_isSaving && !maximumAttemptsReached,
                    onDigitPressed: _addDigit,
                    onBackspacePressed: _removeLastDigit,
                  ),
                  const SizedBox(height: 20),
                  if (_isSaving)
                    const Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Actualizando PIN...'),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
