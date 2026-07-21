import 'backup_constants.dart';

abstract final class BackupPaths {
  static String buildFileName(DateTime dateTime) {
    final String year = dateTime.year.toString().padLeft(4, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String second = dateTime.second.toString().padLeft(2, '0');

    return 'MiSalud_Backup_$year$month${day}_'
        '$hour$minute$second.${BackupConstants.fileExtension}';
  }

  static bool hasValidExtension(String path) {
    return path.toLowerCase().endsWith('.${BackupConstants.fileExtension}');
  }
}
