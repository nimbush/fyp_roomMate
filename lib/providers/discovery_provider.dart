import 'package:flutter/foundation.dart';
import '../models/discovery_user_model.dart';
import '../services/api_service.dart';
import '../services/discovery_service.dart';
import '../services/swipe_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  List<DiscoveryUserModel> _candidates = [];
  bool _isLoading = false;
  String? _error;

  List<DiscoveryUserModel> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _candidates.isEmpty;

  Future<void> loadDiscovery(int userId) async {
    _setLoading(true);
    try {
      _candidates = await DiscoveryService.getDiscovery(userId);
      _error = null;
    } catch (e) {
      _error = friendlyError(e, 'Could not load suggestions.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> swipe({
    required int swiperId,
    required int swipedId,
    required bool liked,
  }) async {
    // Remove optimistically so the deck advances without waiting on the network,
    // but remember the card (and its position) so a failed swipe can be undone
    // instead of silently discarding the candidate.
    final index = _candidates.indexWhere((c) => c.id == swipedId);
    if (index == -1) return;
    final removed = _candidates.removeAt(index);
    notifyListeners();

    try {
      await SwipeService.recordSwipe(
        swiperId: swiperId,
        swipedId: swipedId,
        liked: liked,
      );
    } on ApiException catch (e) {
      // A duplicate swipe means the server already recorded it — the card is
      // correctly gone, so don't restore it.
      if (e.statusCode != 400) {
        _candidates.insert(index.clamp(0, _candidates.length), removed);
      }
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _candidates.insert(index.clamp(0, _candidates.length), removed);
      _error = friendlyError(e, 'Could not save your swipe. Please try again.');
      notifyListeners();
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
