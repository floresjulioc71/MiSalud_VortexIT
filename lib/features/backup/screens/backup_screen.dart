import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/backup/models/backup_result.dart';
import '../../../core/backup/services/backup_file_service.dart';
import '../../../core/backup/services/backup_service.dart';
import '../../../core/backup/utils/backup_constants.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = const BackupService();
  final BackupFileService _backupFileService = const BackupFileService();

  bool _isWorking = false;

  Future<void> _createBackup() async {
    if (_isWorking) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final BackupResult<Map<String, dynamic>> result = await _backupService
          .createBackupData();

      if (!result.isSuccess || result.data == null) {
        _showMessage(
          result.message ?? 'No fue posible crear el respaldo.',
          isError: true,
        );
        return;
      }

      final DateTime now = DateTime.now();

      final String fileName =
          'MiSalud_backup_${_formatDateTime(now)}.'
          '${BackupConstants.fileExtension}';

      final File? file = await _backupFileService.saveBackup(
        backup: result.data!,
        defaultFileName: fileName,
      );

      if (file == null) {
        _showMessage('Se canceló la creación del respaldo.');
        return;
      }

      _showMessage('Respaldo guardado correctamente en:\n${file.path}');
    } catch (error) {
      _showMessage('No fue posible crear el respaldo.\n$error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_isWorking) {
      return;
    }

    final bool confirmed = await _confirmRestore();

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final Map<String, dynamic>? backup = await _backupFileService
          .openBackup();

      if (backup == null) {
        _showMessage('Se canceló la restauración.');
        return;
      }

      final BackupResult<void> result = await _backupService.restoreBackupData(
        backup,
      );

      if (!result.isSuccess) {
        _showMessage(
          result.message ?? 'No fue posible restaurar el respaldo.',
          isError: true,
        );
        return;
      }

      _showMessage(
        'Los datos fueron restaurados correctamente. '
        'Volvé al inicio para ver la información recuperada.',
      );
    } catch (error) {
      _showMessage(
        'No fue posible restaurar el respaldo.\n$error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<bool> _confirmRestore() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Restaurar respaldo'),
          content: const Text(
            'La restauración reemplazará los datos locales actuales '
            'por los contenidos en el respaldo seleccionado.\n\n'
            '¿Deseás continuar?',
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
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 6 : 4),
        ),
      );
  }

  String _formatDateTime(DateTime dateTime) {
    final String year = dateTime.year.toString().padLeft(4, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '${year}_${month}_${day}_${hour}_$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo y restauración')),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                const Icon(Icons.health_and_safety_outlined, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Protegé tu información médica',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Los respaldos se guardan localmente en el lugar que elijas. '
                  'La aplicación no envía tus datos a servidores ni a la nube.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Icon(Icons.save_alt, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Crear respaldo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Genera un archivo .msb con los datos locales '
                          'de la aplicación.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _isWorking ? null : _createBackup,
                          icon: const Icon(Icons.save),
                          label: const Text('Elegir dónde guardarlo'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Icon(Icons.settings_backup_restore, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Restaurar respaldo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Selecciona un archivo .msb creado anteriormente. '
                          'Los datos actuales serán reemplazados.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _isWorking ? null : _restoreBackup,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Seleccionar respaldo'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Guardá una copia en un dispositivo seguro. '
                            'La restauración no puede deshacerse.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isWorking)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Procesando respaldo...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
