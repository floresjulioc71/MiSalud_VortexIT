enum BackupResultStatus {
  success,
  invalidFile,
  incompatibleVersion,
  corrupted,
  cancelled,
  failure,
}

class BackupResult<T> {
  final BackupResultStatus status;
  final T? data;
  final String? message;
  final Object? error;

  const BackupResult._({
    required this.status,
    this.data,
    this.message,
    this.error,
  });

  const BackupResult.success({T? data, String? message})
    : this._(status: BackupResultStatus.success, data: data, message: message);

  const BackupResult.failure({
    BackupResultStatus status = BackupResultStatus.failure,
    String? message,
    Object? error,
  }) : this._(status: status, message: message, error: error);

  bool get isSuccess => status == BackupResultStatus.success;

  bool get isFailure => !isSuccess;
}
