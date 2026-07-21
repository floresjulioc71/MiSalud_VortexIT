class SecuritySettings {
  final bool pinEnabled;
  final bool biometricEnabled;
  final int failedAttempts;

  const SecuritySettings({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.failedAttempts,
  });

  factory SecuritySettings.empty() {
    return const SecuritySettings(
      pinEnabled: false,
      biometricEnabled: false,
      failedAttempts: 0,
    );
  }

  SecuritySettings copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    int? failedAttempts,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}
