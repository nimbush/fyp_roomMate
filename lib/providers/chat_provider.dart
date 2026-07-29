import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _ws = WebSocketService();

  List<ConversationModel> _conversations = [];
  final Map<int, List<ChatMessageModel>> _messages = {};
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ChatMessageModel> getMessages(int matchId) =>
      _messages[matchId] ?? [];

  Future<void> connect() async {
    final token = await StorageService.getToken();
    if (token != null) _ws.connect(token);
  }

  Future<void> loadConversations(int userId) async {
    _setLoading(true);
    try {
      _conversations = await ChatService.getConversations(userId);
      _error = null;
    } catch (e) {
      _error = friendlyError(e, 'Could not load your conversations.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMessages(int matchId) async {
    _setLoading(true);
    try {
      _messages[matchId] = await ChatService.getMessages(matchId);
      _ws.subscribeToChat(matchId, (msg) {
        _messages[matchId] ??= [];
        _messages[matchId]!.add(msg);
        notifyListeners();
      });
      _error = null;
    } catch (e) {
      _error = friendlyError(e, 'Could not load messages.');
    } finally {
      _setLoading(false);
    }
  }

  void sendMessage(int matchId, String content) {
    _ws.sendMessage(matchId, content);
  }

  void leaveChat(int matchId) {
    _ws.unsubscribeFromChat(matchId);
  }

  void disconnect() {
    _ws.disconnect();
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
