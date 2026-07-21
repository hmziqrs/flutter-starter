enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.value);

  final String value;

  static AppEnvironment parse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final environment in values) {
      if (environment.value == normalized) {
        return environment;
      }
    }

    if (normalized.isEmpty) {
      throw const AppEnvironmentException('APP_ENV is required.');
    }

    throw AppEnvironmentException(
      'Unknown APP_ENV "$value". Expected development, staging, or production.',
    );
  }
}

final class AppEnvironmentException implements Exception {
  const AppEnvironmentException(this.message);

  final String message;

  @override
  String toString() => 'AppEnvironmentException: $message';
}
