class AppConfig {
  // 10.0.2.2 routes to the host machine from an Android emulator
  static const String baseUrl = 'http://10.0.2.2:8010';
  static const String wsUrl = 'ws://10.0.2.2:8010/ws-chat';
  static const String imageBaseUrl = 'http://10.0.2.2:8010/images/';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
