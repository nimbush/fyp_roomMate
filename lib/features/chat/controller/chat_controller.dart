import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/api_exception.dart';
import 'package:roommate_finder/common/utils/generic_state.dart';
import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/chat/model/chat_message_model.dart';
import 'package:roommate_finder/features/chat/model/conversation_model.dart';
import 'package:roommate_finder/features/chat/repo/chat_repository.dart';
import 'package:roommate_finder/features/chat/repo/chat_socket.dart';

final chatRepoProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(tokenBaseRepoProvider)),
);

/// One STOMP socket for the whole app; per-match subscriptions are managed by
/// each [ChatController]. Disconnected when the container goes down.
final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket(ref.watch(localStorageProvider));
  ref.onDispose(socket.disconnect);
  return socket;
});

/// Conversation (thread) list. autoDispose: reloaded fresh when the Messages
/// tab is revisited.
final conversationListControllerProvider = StateNotifierProvider.autoDispose<
    ConversationListController, GenericState<List<ConversationModel>>>(
  (ref) => ConversationListController(
    ref.watch(chatRepoProvider),
    ref.watch(localStorageProvider),
  ),
);

class ConversationListController
    extends StateNotifier<GenericState<List<ConversationModel>>> {
  ConversationListController(this._repo, this._storage) : super(const Empty());

  final ChatRepository _repo;
  final LocalStorage _storage;

  Future<void> loadConversations() async {
    state = const Loading();
    try {
      final userId = await _storage.getUserId();
      if (userId == null) {
        state = const Failure('Your session has expired. Please sign in again.');
        return;
      }
      final conversations = await _repo.getConversations(userId);
      if (mounted) state = Success(conversations);
    } catch (e) {
      if (mounted) {
        state = Failure(friendlyError(e, 'Could not load your conversations.'));
      }
    }
  }
}

/// State for one open conversation: its message history plus the signed-in
/// user's id (needed to lay out bubbles left/right).
class ChatState {
  const ChatState({
    this.messages = const Empty(),
    this.currentUserId = 0,
  });

  final GenericState<List<ChatMessageModel>> messages;
  final int currentUserId;

  ChatState copyWith({
    GenericState<List<ChatMessageModel>>? messages,
    int? currentUserId,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        currentUserId: currentUserId ?? this.currentUserId,
      );
}

/// Per-match chat controller. family: each conversation owns its own state;
/// autoDispose: leaving the screen tears the controller down, which
/// unsubscribes the STOMP topic in [dispose].
final chatControllerProvider = StateNotifierProvider.autoDispose
    .family<ChatController, ChatState, int>(
  (ref, matchId) => ChatController(
    ref.watch(chatRepoProvider),
    ref.watch(chatSocketProvider),
    ref.watch(localStorageProvider),
    matchId,
  ),
);

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._repo, this._socket, this._storage, this.matchId)
      : super(const ChatState());

  final ChatRepository _repo;
  final ChatSocket _socket;
  final LocalStorage _storage;
  final int matchId;

  Future<void> loadMessages() async {
    state = state.copyWith(messages: const Loading());
    try {
      final userId = await _storage.getUserId() ?? 0;
      final history = await _repo.getMessages(matchId);
      _socket.subscribeToChat(matchId, _onIncoming);
      // Connect after registering the callback: `_onConnected` replays the
      // subscription map, so a slow handshake can't drop this topic.
      await _socket.connect();
      if (mounted) {
        state = ChatState(messages: Success(history), currentUserId: userId);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            messages: Failure(friendlyError(e, 'Could not load messages.')));
      }
    }
  }

  void _onIncoming(ChatMessageModel msg) {
    if (!mounted) return;
    final current = state.messages.dataOrNull() ?? const <ChatMessageModel>[];
    state = state.copyWith(messages: Success([...current, msg]));
  }

  void sendMessage(String content) {
    _socket.sendMessage(matchId, content);
  }

  @override
  void dispose() {
    _socket.unsubscribeFromChat(matchId);
    super.dispose();
  }
}
