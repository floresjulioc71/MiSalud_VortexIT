import 'package:flutter/material.dart';

import '../models/health_control.dart';
import '../services/health_control_storage_service.dart';

class HealthControlFormScreen extends StatefulWidget {
  final HealthControl? item;

  const HealthControlFormScreen({super.key, this.item});

  @override
  State<HealthControlFormScreen> createState() =>
      _HealthControlFormScreenState();
}

class _HealthControlFormScreenState extends State<HealthControlFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _recordedAt;
  late final TextEditingController _systolic;
  late final TextEditingController _diastolic;
  late final TextEditingController _heartRate;
  late final TextEditingController _oxygen;
  late final TextEditingController _temperature;
  late final TextEditingController _weight;
  late final TextEditingController _glucose;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final HealthControl? item = widget.item;
    _recordedAt = item?.recordedAt ?? DateTime.now();
    _systolic = TextEditingController(
      text: item?.systolicPressure?.toString() ?? '',
    );
    _diastolic = TextEditingController(
      text: item?.diastolicPressure?.toString() ?? '',
    );
    _heartRate = TextEditingController(text: item?.heartRate?.toString() ?? '');
    _oxygen = TextEditingController(
      text: item?.oxygenSaturation?.toString() ?? '',
    );
    _temperature = TextEditingController(
      text: item?.temperature?.toString() ?? '',
    );
    _weight = TextEditingController(text: item?.weight?.toString() ?? '');
    _glucose = TextEditingController(
      text: item?.bloodGlucose?.toString() ?? '',
    );
    _notes = TextEditingController(text: item?.notes ?? '');
  }

  @override
  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      _systolic,
      _diastolic,
      _heartRate,
      _oxygen,
      _temperature,
      _weight,
      _glucose,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  int? _int(TextEditingController c) => int.tryParse(c.text.trim());
  double? _double(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _rangeValidator(String? value, int min, int max, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < min || parsed > max) {
      return '$label fuera de rango.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final HealthControl item = HealthControl(
      id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      recordedAt: _recordedAt,
      systolicPressure: _int(_systolic),
      diastolicPressure: _int(_diastolic),
      heartRate: _int(_heartRate),
      oxygenSaturation: _int(_oxygen),
      temperature: _double(_temperature),
      weight: _double(_weight),
      bloodGlucose: _double(_glucose),
      notes: _notes.text.trim(),
    );
    if (!item.hasMeasurements && item.notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresá al menos una medición u observación.'),
        ),
      );
      return;
    }
    await HealthControlStorageService.saveItem(item);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Nuevo control' : 'Editar control'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            InkWell(
              onTap: _selectDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha y hora',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(_formatDateTime(_recordedAt)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _systolic,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Presión sistólica',
                      suffixText: 'mmHg',
                    ),
                    validator: (v) =>
                        _rangeValidator(v, 40, 300, 'Presión sistólica'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diastolic,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Presión diastólica',
                      suffixText: 'mmHg',
                    ),
                    validator: (v) =>
                        _rangeValidator(v, 20, 200, 'Presión diastólica'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heartRate,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Frecuencia cardíaca',
                suffixText: 'lpm',
                prefixIcon: Icon(Icons.favorite_outline),
              ),
              validator: (v) =>
                  _rangeValidator(v, 20, 300, 'Frecuencia cardíaca'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oxygen,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Saturación de oxígeno',
                suffixText: '%',
                prefixIcon: Icon(Icons.air),
              ),
              validator: (v) => _rangeValidator(v, 30, 100, 'Saturación'),
            ),
            const SizedBox(height: 16),
            _decimalField(
              _temperature,
              'Temperatura',
              '°C',
              Icons.thermostat_outlined,
            ),
            const SizedBox(height: 16),
            _decimalField(_weight, 'Peso', 'kg', Icons.monitor_weight_outlined),
            const SizedBox(height: 16),
            _decimalField(
              _glucose,
              'Glucemia',
              'mg/dL',
              Icons.water_drop_outlined,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar control'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decimalField(
    TextEditingController controller,
    String label,
    String suffix,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon),
      ),
      validator: (String? value) {
        if (value == null || value.trim().isEmpty) return null;
        final double? parsed = double.tryParse(
          value.trim().replaceAll(',', '.'),
        );
        return parsed == null || parsed <= 0
            ? 'Ingresá un valor válido.'
            : null;
      },
    );
  }

  static String _formatDateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
