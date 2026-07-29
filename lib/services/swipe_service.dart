import 'api_service.dart';

class SwipeService {
  static Future<void> recordSwipe({
    required int swiperId,
    required int swipedId,
    required bool liked,
  }) async {
    await ApiService.post('/api/swipes', {
      'swiperId': swiperId,
      'swipedId': swipedId,
      'liked': liked,
    });
  }
}
