import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/features/chat/model/chat_message_model.dart';
import 'package:roommate_finder/features/chat/model/conversation_model.dart';

/// REST side of chat: message history and the conversation (thread) list.
/// Live traffic goes through `ChatSocket`.
class ChatRepository {
  ChatRepository(this._repo);

  final BaseRepository _repo;

  Future<List<ChatMessageModel>> getMessages(int matchId) =>
      _repo.get(RequestInput<List<ChatMessageModel>>(
        path: '/api/chat/$matchId/messages',
        parse: (json) => (json as List<dynamic>)
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));

  Future<List<ConversationModel>> getConversations(int userId) =>
      _repo.get(RequestInput<List<ConversationModel>>(
        path: '/api/chat/conversations?userId=$userId',
        parse: (json) => (json as List<dynamic>)
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ));
}
