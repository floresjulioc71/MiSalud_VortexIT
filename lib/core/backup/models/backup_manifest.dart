class BackupManifest {
  final int version;
  final DateTime createdAt;
  final String application;
  final String databaseFile;
  final String checksum;

  const BackupManifest({
    required this.version,
    required this.createdAt,
    required this.application,
    required this.databaseFile,
    required this.checksum,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'application': application,
      'databaseFile': databaseFile,
      'checksum': checksum,
    };
  }

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      version: json['version'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      application: json['application'] as String,
      databaseFile: json['databaseFile'] as String,
      checksum: json['checksum'] as String,
    );
  }
}
