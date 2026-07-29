import '../models/match_model.dart';
import 'api_service.dart';

class MatchService {
  static Future<List<MatchModel>> getAllMatches(int userId) async {
    final data = await ApiService.get('/api/matches/user/$userId');
    return (data as List<dynamic>)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<MatchModel>> getAcceptedMatches(int userId) async {
    final data = await ApiService.get('/api/matches/user/$userId/accepted');
    return (data as List<dynamic>)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<MatchModel>> getPendingMatches(int userId) async {
    final data = await ApiService.get('/api/matches/user/$userId/pending');
    return (data as List<dynamic>)
        .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<MatchModel> acceptMatch(int matchId) async {
    final data = await ApiService.put('/api/matches/accept/$matchId');
    return MatchModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<MatchModel> rejectMatch(int matchId) async {
    final data = await ApiService.put('/api/matches/reject/$matchId');
    return MatchModel.fromJson(data as Map<String, dynamic>);
  }
}
