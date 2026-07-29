import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../services/api_service.dart';
import '../services/match_service.dart';

class MatchProvider extends ChangeNotifier {
  List<MatchModel> _accepted = [];
  List<MatchModel> _pending = [];
  bool _isLoading = false;
  String? _error;

  List<MatchModel> get accepted => _accepted;
  List<MatchModel> get pending => _pending;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMatches(int userId) async {
    _setLoading(true);
    try {
      _accepted = await MatchService.getAcceptedMatches(userId);
      _pending = await MatchService.getPendingMatches(userId);
      _error = null;
    } catch (e) {
      _error = friendlyError(e, 'Could not load your matches.');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptMatch(int matchId) async {
    try {
      final updated = await MatchService.acceptMatch(matchId);
      _pending.removeWhere((m) => m.id == matchId);
      _accepted.add(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Could not accept this match.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectMatch(int matchId) async {
    try {
      await MatchService.rejectMatch(matchId);
      _pending.removeWhere((m) => m.id == matchId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e, 'Could not decline this match.');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
