import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../widgets/pin_indicator.dart';
import '../widgets/pin_keyboard.dart';

enum _PinCreationStep { create, confirm }

class CreatePinScreen extends StatefulWidget {
  final VoidCallback? onPinCreated;

  const CreatePinScreen({super.key, this.onPinCreated});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  static const int _pinLength = 4;

  _PinCreationStep _step = _PinCreationStep.create;

  String _enteredPin = '';
  String _firstPin = '';
  String? _errorMessage;

  bool _isSaving = false;

  String get _title {
    switch (_step) {
      case _PinCreationStep.create:
        return 'Crear PIN';
      case _PinCreationStep.confirm:
        return 'Confirmar PIN';
    }
  }

  String get _description {
    switch (_step) {
      case _PinCreationStep.create:
        return 'Ingresá un PIN de $_pinLength dígitos para proteger tus datos.';
      case _PinCreationStep.confirm:
        return 'Ingresá nuevamente el mismo PIN para confirmarlo.';
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
      Future<void>.delayed(
        const Duration(milliseconds: 180),
        _processCompletedPin,
      );
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

  Future<void> _processCompletedPin() async {
    if (!mounted || _enteredPin.length != _pinLength) {
      return;
    }

    if (_step == _PinCreationStep.create) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _step = _PinCreationStep.confirm;
        _errorMessage = null;
      });

      return;
    }

    if (_enteredPin != _firstPin) {
      setState(() {
        _enteredPin = '';
        _firstPin = '';
        _step = _PinCreationStep.create;
        _errorMessage =
            'Los PIN no coinciden. Ingresá nuevamente el nuevo PIN.';
      });

      return;
    }

    await _savePin();
  }

  Future<void> _savePin() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await SecurityService.createPin(_enteredPin);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN configurado correctamente.')),
      );

      final VoidCallback? callback = widget.onPinCreated;

      if (callback != null) {
        callback();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _enteredPin = '';
        _firstPin = '';
        _step = _PinCreationStep.create;
        _isSaving = false;
        _errorMessage = 'No se pudo guardar el PIN. Intentá nuevamente.';
      });
    }
  }

  void _restartCreation() {
    if (_isSaving) {
      return;
    }

    setState(() {
      _enteredPin = '';
      _firstPin = '';
      _step = _PinCreationStep.create;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = _errorMessage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: <Widget>[
          if (_step == _PinCreationStep.confirm)
            IconButton(
              tooltip: 'Comenzar nuevamente',
              onPressed: _isSaving ? null : _restartCreation,
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
                      _step == _PinCreationStep.create
                          ? Icons.lock_outline
                          : Icons.verified_user_outlined,
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
                    hasError: hasError,
                  ),
                  SizedBox(
                    height: 56,
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
                    enabled: !_isSaving,
                    onDigitPressed: _addDigit,
                    onBackspacePressed: _removeLastDigit,
                  ),
                  const SizedBox(height: 20),
                  if (_isSaving)
                    const Column(
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Guardando PIN...'),
                      ],
                    ),
                  if (!_isSaving && _step == _PinCreationStep.confirm)
                    TextButton.icon(
                      onPressed: _restartCreation,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Elegir otro PIN'),
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
