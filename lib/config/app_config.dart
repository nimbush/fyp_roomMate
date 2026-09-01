class AppConfig {
  /// Backend host. AWS Elastic IP, so it survives instance restarts.
  ///
  /// Override at build time without editing this file:
  ///   flutter run --dart-define=API_HOST=10.0.2.2:8015
  /// (10.0.2.2 is how an Android emulator reaches the host machine.)
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '13.203.84.26:8015',
  );

  static const String baseUrl = 'http://$_host';
  static const String wsUrl = 'ws://$_host/ws-chat';
  static const String imageBaseUrl = 'http://$_host/images/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
