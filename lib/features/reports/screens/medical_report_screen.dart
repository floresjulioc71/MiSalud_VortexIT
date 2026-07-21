import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../family/services/family_storage_service.dart';
import '../models/medical_report_data.dart';
import '../services/medical_pdf_generator_service.dart';
import '../services/medical_report_builder_service.dart';

class MedicalReportScreen extends StatefulWidget {
  const MedicalReportScreen({super.key});

  @override
  State<MedicalReportScreen> createState() => _MedicalReportScreenState();
}

class _MedicalReportScreenState extends State<MedicalReportScreen> {
  File? _generatedFile;
  bool _isGenerating = false;
  bool _isOpening = false;
  bool _isSharing = false;

  String get _patientName {
    return FamilyStorageService.activeMember.name.trim();
  }

  String get _familyMemberId {
    return FamilyStorageService.activeMember.id;
  }

  Future<void> _generateReport() async {
    if (_isGenerating) {
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final MedicalReportData report = await MedicalReportBuilderService.build(
        familyMemberId: _familyMemberId,
        patientName: _patientName,
      );

      final File file = await MedicalPdfGeneratorService.generate(report);

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedFile = file;
      });

      _showMessage('Informe PDF generado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo generar el informe PDF: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _openReport() async {
    final File? file = _generatedFile;

    if (file == null) {
      _showMessage('Primero debés generar el informe PDF.', isError: true);
      return;
    }

    if (!await file.exists()) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generatedFile = null;
      });

      _showMessage(
        'El archivo generado ya no existe. Generá el informe nuevamente.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isOpening = true;
    });

    try {
      final OpenResult result = await OpenFilex.open(file.path);

      if (!mounted) {
        return;
      }

      if (result.type != ResultType.done) {
        _showMessage(
          result.message.isNotEmpty
              ? result.message
              : 'No se pudo abrir el archivo PDF.',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo abrir el informe: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  Future<void> _shareReport() async {
    final File? file = _generatedFile;

    if (file == null) {
      _showMessage('Primero debés generar el informe PDF.', isError: true);
      return;
    }

    if (!await file.exists()) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generatedFile = null;
      });

      _showMessage(
        'El archivo generado ya no existe. Generá el informe nuevamente.',
        isError: true,
      );
      return;
    }

    if (Platform.isLinux) {
      _showMessage(
        'Linux no permite compartir archivos mediante share_plus. '
        'Podés abrir el PDF y enviarlo manualmente.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          title: 'Historia clínica de $_patientName',
          subject: 'Informe médico personal',
          text: 'Informe médico personal generado con MiSalud VortexIT.',
          files: <XFile>[XFile(file.path, mimeType: 'application/pdf')],
        ),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.unavailable) {
        _showMessage(
          'La función de compartir no está disponible en este dispositivo.',
          isError: true,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('No se pudo compartir el informe: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
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
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final File? generatedFile = _generatedFile;
    final bool hasGeneratedFile = generatedFile != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Informe PDF')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: <Widget>[
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.picture_as_pdf_outlined),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Informe médico de'),
                        Text(
                          _patientName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Text(
            'Historia clínica personal',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'El informe reúne el perfil médico, antecedentes, alergias, '
            'medicamentos, vacunas, cirugías, estudios, documentos clínicos, '
            'médicos, consultas y controles de salud del integrante activo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xLarge),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateReport,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(
              _isGenerating
                  ? 'Generando informe...'
                  : hasGeneratedFile
                  ? 'Generar nuevamente'
                  : 'Generar informe PDF',
            ),
          ),
          if (hasGeneratedFile) ...<Widget>[
            const SizedBox(height: AppSpacing.xLarge),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          child: Text(
                            'Informe generado',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      generatedFile.path,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isOpening ? null : _openReport,
                            icon: _isOpening
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.open_in_new),
                            label: const Text('Abrir'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isSharing ? null : _shareReport,
                            icon: _isSharing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.share_outlined),
                            label: const Text('Compartir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  const Expanded(
                    child: Text(
                      'Este documento contiene información médica personal. '
                      'Guardalo y compartilo únicamente con personas de confianza.',
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
