import '../models/discovery_user_model.dart';
import 'api_service.dart';

class DiscoveryService {
  static Future<List<DiscoveryUserModel>> getDiscovery(int userId) async {
    final data = await ApiService.get('/api/discovery?userId=$userId');
    return (data as List<dynamic>)
        .map((e) => DiscoveryUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
