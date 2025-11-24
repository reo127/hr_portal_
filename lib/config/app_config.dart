enum Environment {
  development,
  production,
}

class AppConfig {
  // ⚠️ CHANGE THIS TO SWITCH BETWEEN ENVIRONMENTS ⚠️
  // static const Environment currentEnvironment = Environment.production;
  static const Environment currentEnvironment = Environment.development;

  // API Base URLs
  static const String _devBaseUrl = 'https://dev.hrp.aroha.co.in/api'; 
  static const String _prodBaseUrl = 'https://hrp.aroha.co.in/api';

  // Get current base URL based on environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _devBaseUrl;
      case Environment.production:
        return _prodBaseUrl;
    }
  }

  // Environment name for display
  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  // Check if in development mode
  static bool get isDevelopment => currentEnvironment == Environment.development;

  // Check if in production mode
  static bool get isProduction => currentEnvironment == Environment.production;

  // API timeout settings (you can have different timeouts for dev/prod)
  static Duration get connectTimeout {
    return isDevelopment
        ? const Duration(seconds: 60)  // Longer timeout for dev
        : const Duration(seconds: 30);
  }

  static Duration get receiveTimeout {
    return isDevelopment
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
  }
}
