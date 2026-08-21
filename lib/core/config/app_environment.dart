enum AppEnvironment { development, production }

class AppConfig {
  final AppEnvironment environment;
  final String appName;

  const AppConfig({required this.environment, required this.appName});

  bool get isDevelopment => environment == AppEnvironment.development;

  bool get isProduction => environment == AppEnvironment.production;
}
