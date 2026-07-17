import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../diagnoses/models/diagnosis_entry.dart';

class DiagnosisEditScreen extends StatefulWidget {
  final String initialDescription;

  const DiagnosisEditScreen({super.key, this.initialDescription = ''});

  @override
  State<DiagnosisEditScreen> createState() => _DiagnosisEditScreenState();
}

class _DiagnosisEditScreenState extends State<DiagnosisEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final DateTime now = DateTime.now();

    final DiagnosisEntry result = DiagnosisEntry(
      id: now.microsecondsSinceEpoch.toString(),
      primarySystem: DiagnosisSystem.freeText,
      primaryCode: '',
      description: _descriptionController.text.trim(),
      icd10Code: '',
      snomedCtCode: '',
      icpc2Code: '',
      terminologyVersion: '',
      status: DiagnosisStatus.active,
      origin: DiagnosisOrigin.selfRecord,
      diagnosisDate: now,
      notes: '',
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo diagnóstico')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            TextFormField(
              controller: _descriptionController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Diagnóstico',
                prefixIcon: Icon(Icons.medical_information_outlined),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribí el diagnóstico.';
                }

                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xLarge),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(AppIcons.save),
              label: const Text('Agregar diagnóstico'),
            ),
          ],
        ),
      ),
    );
  }
}
