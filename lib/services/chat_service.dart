import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import 'api_service.dart';

class ChatService {
  static Future<List<ChatMessageModel>> getMessages(int matchId) async {
    final data = await ApiService.get('/api/chat/$matchId/messages');
    return (data as List<dynamic>)
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ConversationModel>> getConversations(int userId) async {
    final data = await ApiService.get('/api/chat/conversations?userId=$userId');
    return (data as List<dynamic>)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
