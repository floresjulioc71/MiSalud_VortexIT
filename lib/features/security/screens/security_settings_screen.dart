import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _refreshSecurityState();
  }

  void _refreshSecurityState() {
    setState(() {
      _pinEnabled = SecurityService.hasPin();
    });
  }

  Future<void> _createPin() async {
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.security);

    if (!mounted) {
      return;
    }

    if (result == true) {
      _refreshSecurityState();
    }
  }

  Future<void> _changePin() async {
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.changePin);

    if (!mounted) {
      return;
    }

    if (result == true) {
      _refreshSecurityState();
    }
  }

  Future<void> _removePin() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Eliminar protección'),
          content: const Text(
            'La aplicación dejará de solicitar el PIN al iniciar. '
            'Los datos médicos quedarán accesibles sin bloqueo.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar PIN'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await SecurityService.removePin();

    if (!mounted) {
      return;
    }

    _refreshSecurityState();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La protección con PIN fue desactivada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            color: _pinEnabled
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _pinEnabled
                        ? colorScheme.primary
                        : colorScheme.outline,
                    foregroundColor: _pinEnabled
                        ? colorScheme.onPrimary
                        : colorScheme.surface,
                    child: Icon(
                      _pinEnabled
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _pinEnabled
                              ? 'Protección activada'
                              : 'Protección desactivada',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pinEnabled
                              ? 'MiSalud solicitará el PIN para acceder.'
                              : 'La aplicación puede abrirse sin PIN.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Protección con PIN',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (!_pinEnabled)
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_moderator_outlined),
                title: const Text('Crear PIN'),
                subtitle: const Text(
                  'Protegé la información médica con un PIN de 4 dígitos.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _createPin,
              ),
            ),
          if (_pinEnabled) ...<Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.password_outlined),
                title: const Text('Cambiar PIN'),
                subtitle: const Text('Reemplazá el PIN actual por uno nuevo.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _changePin,
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.lock_open_outlined,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Eliminar PIN',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text(
                  'Desactivá el bloqueo de acceso a la aplicación.',
                ),
                onTap: _removePin,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Biometría',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              enabled: false,
              leading: Icon(Icons.fingerprint),
              title: Text('Huella o reconocimiento biométrico'),
              subtitle: Text(
                'Disponible en la próxima etapa del módulo de seguridad.',
              ),
              trailing: Icon(Icons.hourglass_empty),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'El PIN no se guarda como texto. '
                      'MiSalud almacena únicamente una representación '
                      'criptográfica para verificarlo.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
