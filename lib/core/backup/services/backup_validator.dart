import '../models/backup_manifest.dart';
import '../utils/backup_constants.dart';

class BackupValidator {
  const BackupValidator();

  bool validateManifest(BackupManifest manifest) {
    if (manifest.application != BackupConstants.applicationName) {
      return false;
    }

    if (manifest.version < BackupConstants.minimumSupportedBackupVersion) {
      return false;
    }

    if (manifest.databaseFile.trim().isEmpty) {
      return false;
    }

    if (manifest.checksum.trim().isEmpty) {
      return false;
    }

    return true;
  }
}
