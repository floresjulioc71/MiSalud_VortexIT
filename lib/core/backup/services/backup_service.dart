import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backup_manifest.dart';
import '../models/backup_result.dart';
import '../utils/backup_constants.dart';
import 'backup_validator.dart';
import 'checksum_service.dart';

class BackupService {
  final ChecksumService checksumService;
  final BackupValidator validator;

  const BackupService({
    this.checksumService = const ChecksumService(),
    this.validator = const BackupValidator(),
  });

  Future<BackupResult<Map<String, dynamic>>> createBackupData() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      // Fuerza la lectura de los datos más recientes guardados en disco.
      await preferences.reload();

      final List<String> keys = preferences.getKeys().toList()..sort();

      final Map<String, dynamic> database = <String, dynamic>{};

      for (final String key in keys) {
        final Object? value = preferences.get(key);

        if (_isSupportedValue(value)) {
          database[key] = _normalizeValue(value);
        }
      }

      if (database.isEmpty) {
        return const BackupResult<Map<String, dynamic>>.failure(
          status: BackupResultStatus.invalidFile,
          message:
              'No se encontraron datos locales para incluir en el respaldo.',
        );
      }

      final String databaseJson = jsonEncode(database);
      final String checksum = checksumService.calculateFromString(databaseJson);

      final BackupManifest manifest = BackupManifest(
        version: BackupConstants.currentBackupVersion,
        createdAt: DateTime.now().toUtc(),
        application: BackupConstants.applicationName,
        databaseFile: BackupConstants.databaseFileName,
        checksum: checksum,
      );

      return BackupResult<Map<String, dynamic>>.success(
        data: <String, dynamic>{
          'manifest': manifest.toJson(),
          'database': database,
        },
        message:
            'Respaldo preparado correctamente con ${database.length} registros.',
      );
    } catch (error, stackTrace) {
      debugPrint('ERROR AL CREAR RESPALDO: $error');
      debugPrintStack(stackTrace: stackTrace);

      return BackupResult<Map<String, dynamic>>.failure(
        message: 'No fue posible crear el respaldo local.\n$error',
        error: error,
      );
    }
  }

  BackupResult<Map<String, dynamic>> validateBackupData(
    Map<String, dynamic> backup,
  ) {
    try {
      final Object? rawManifest = backup['manifest'];
      final Object? rawDatabase = backup['database'];

      if (rawManifest is! Map || rawDatabase is! Map) {
        return const BackupResult<Map<String, dynamic>>.failure(
          status: BackupResultStatus.invalidFile,
          message: 'El archivo no contiene una estructura de respaldo válida.',
        );
      }

      final BackupManifest manifest = BackupManifest.fromJson(
        Map<String, dynamic>.from(rawManifest),
      );

      if (!validator.validateManifest(manifest)) {
        return const BackupResult<Map<String, dynamic>>.failure(
          status: BackupResultStatus.incompatibleVersion,
          message: 'El manifiesto del respaldo no es compatible.',
        );
      }

      final Map<String, dynamic> database = Map<String, dynamic>.from(
        rawDatabase,
      );

      if (database.isEmpty) {
        return const BackupResult<Map<String, dynamic>>.failure(
          status: BackupResultStatus.invalidFile,
          message: 'El respaldo no contiene datos para restaurar.',
        );
      }

      for (final MapEntry<String, dynamic> entry in database.entries) {
        if (entry.key.trim().isEmpty || !_isSupportedValue(entry.value)) {
          return BackupResult<Map<String, dynamic>>.failure(
            status: BackupResultStatus.invalidFile,
            message:
                'El respaldo contiene un dato incompatible: "${entry.key}".',
          );
        }
      }

      final String databaseJson = jsonEncode(database);

      final bool checksumIsValid = checksumService.verifyString(
        value: databaseJson,
        expectedChecksum: manifest.checksum,
      );

      if (!checksumIsValid) {
        return const BackupResult<Map<String, dynamic>>.failure(
          status: BackupResultStatus.corrupted,
          message: 'El respaldo está dañado o fue modificado.',
        );
      }

      return BackupResult<Map<String, dynamic>>.success(
        data: database,
        message:
            'Respaldo validado correctamente con ${database.length} registros.',
      );
    } on FormatException catch (error) {
      return BackupResult<Map<String, dynamic>>.failure(
        status: BackupResultStatus.invalidFile,
        message: 'El contenido del respaldo no es válido.',
        error: error,
      );
    } on TypeError catch (error) {
      return BackupResult<Map<String, dynamic>>.failure(
        status: BackupResultStatus.invalidFile,
        message: 'El respaldo contiene tipos de datos inválidos.',
        error: error,
      );
    } catch (error) {
      return BackupResult<Map<String, dynamic>>.failure(
        message: 'No fue posible validar el respaldo.',
        error: error,
      );
    }
  }

  Future<BackupResult<void>> restoreBackupData(
    Map<String, dynamic> backup,
  ) async {
    final BackupResult<Map<String, dynamic>> validation = validateBackupData(
      backup,
    );

    if (!validation.isSuccess || validation.data == null) {
      return BackupResult<void>.failure(
        status: validation.status,
        message: validation.message,
        error: validation.error,
      );
    }

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      await preferences.reload();

      final Map<String, dynamic> database = validation.data!;

      /*
       * Guardamos una copia de los valores que serán modificados.
       * Esta copia permite revertir la restauración si algo falla.
       */
      final Map<String, Object?> previousValues = <String, Object?>{};

      for (final String key in database.keys) {
        previousValues[key] = preferences.get(key);
      }

      final List<String> modifiedKeys = <String>[];

      try {
        /*
         * No usamos preferences.clear().
         *
         * Un respaldo antiguo o incompleto nunca debe borrar información
         * local que no esté incluida dentro del archivo.
         */
        for (final MapEntry<String, dynamic> entry in database.entries) {
          final bool saved = await _savePreferenceValue(
            preferences: preferences,
            key: entry.key,
            value: entry.value,
          );

          if (!saved) {
            throw StateError('No fue posible guardar el dato "${entry.key}".');
          }

          modifiedKeys.add(entry.key);
        }

        await preferences.reload();

        for (final MapEntry<String, dynamic> entry in database.entries) {
          final Object? restoredValue = preferences.get(entry.key);

          if (!_valuesAreEqual(restoredValue, entry.value)) {
            throw StateError(
              'No fue posible verificar el dato "${entry.key}".',
            );
          }
        }
      } catch (error) {
        await _rollbackModifiedValues(
          preferences: preferences,
          previousValues: previousValues,
          modifiedKeys: modifiedKeys,
        );

        return BackupResult<void>.failure(
          message:
              'La restauración no pudo completarse. '
              'Los datos anteriores fueron conservados.',
          error: error,
        );
      }

      return BackupResult<void>.success(
        message:
            'Se restauraron correctamente ${database.length} registros. '
            'Los datos locales no incluidos en el respaldo fueron conservados.',
      );
    } catch (error) {
      return BackupResult<void>.failure(
        message:
            'No fue posible restaurar el respaldo. '
            'No se eliminaron los datos locales.',
        error: error,
      );
    }
  }

  bool _isSupportedValue(Object? value) {
    if (value is String || value is bool || value is int || value is double) {
      return true;
    }

    if (value is List) {
      return value.every((Object? item) => item is String);
    }

    return false;
  }

  Object _normalizeValue(Object? value) {
    if (value == null) {
      throw ArgumentError('Se encontró un valor nulo en SharedPreferences.');
    }

    if (value is String) {
      return value;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value;
    }

    if (value is List) {
      return value
          .map<String>((Object? item) => item?.toString() ?? '')
          .toList();
    }

    throw ArgumentError(
      'Tipo de dato no compatible con el respaldo: ${value.runtimeType}',
    );
  }

  Future<bool> _savePreferenceValue({
    required SharedPreferences preferences,
    required String key,
    required Object? value,
  }) async {
    if (value is String) {
      return preferences.setString(key, value);
    }

    if (value is bool) {
      return preferences.setBool(key, value);
    }

    if (value is int) {
      return preferences.setInt(key, value);
    }

    if (value is double) {
      return preferences.setDouble(key, value);
    }

    if (value is List) {
      final List<String> values = value
          .map((Object? item) => item.toString())
          .toList();

      return preferences.setStringList(key, values);
    }

    return false;
  }

  Future<void> _rollbackModifiedValues({
    required SharedPreferences preferences,
    required Map<String, Object?> previousValues,
    required List<String> modifiedKeys,
  }) async {
    for (final String key in modifiedKeys.reversed) {
      final Object? previousValue = previousValues[key];

      if (previousValue == null) {
        await preferences.remove(key);
        continue;
      }

      await _savePreferenceValue(
        preferences: preferences,
        key: key,
        value: previousValue,
      );
    }

    await preferences.reload();
  }

  bool _valuesAreEqual(Object? first, Object? second) {
    if (first is List && second is List) {
      if (first.length != second.length) {
        return false;
      }

      for (int index = 0; index < first.length; index++) {
        if (first[index].toString() != second[index].toString()) {
          return false;
        }
      }

      return true;
    }

    return first == second;
  }
}
