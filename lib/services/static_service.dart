import 'api_service.dart';

class StaticService {
  static Future<Map<String, dynamic>> getContent(String service) async {
    final data = await ApiService.get('/api/services/$service');
    return data as Map<String, dynamic>;
  }

  static Future<void> submitSupport({
    required String username,
    required String phoneNumber,
    required String email,
    required String title,
    required String body,
  }) async {
    await ApiService.post('/api/support', {
      'username': username,
      'phoneNumber': phoneNumber,
      'email': email,
      'title': title,
      'body': body,
    });
  }
}
