import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:roommate_finder/common/utils/local_storage.dart';
import 'package:roommate_finder/config/app_config.dart';
import 'package:roommate_finder/features/chat/model/chat_message_model.dart';

/// STOMP websocket for live chat. Takes its bearer token from the injected
/// [LocalStorage] so callers never handle raw credentials.
///
/// One socket serves every open chat: per-match topic subscriptions are added
/// and removed as chat screens come and go, and the callback map survives a
/// reconnect so `_onConnected` can restore every live subscription.
class ChatSocket {
  ChatSocket(this._storage);

  final LocalStorage _storage;

  StompClient? _client;
  final Map<int, void Function(ChatMessageModel)> _subscribers = {};
  final Map<int, StompUnsubscribe> _unsubscribers = {};

  /// Activates the socket if it isn't already. Safe to call before every
  /// subscription — an active client is left alone.
  Future<void> connect() async {
    if (_client?.isActive == true) return;
    final token = await _storage.getToken();
    if (token == null) return;
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        onConnect: _onConnected,
        onWebSocketError: (error) => debugPrint('WS error: $error'),
        onDisconnect: (_) => debugPrint('WS disconnected'),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void _onConnected(StompFrame frame) {
    debugPrint('WS connected');
    // Server-side subscriptions died with the old connection; the callback
    // map is the source of truth for what should be live.
    _unsubscribers.clear();
    for (final matchId in List<int>.from(_subscribers.keys)) {
      _subscribeToMatch(matchId);
    }
  }

  void subscribeToChat(int matchId, void Function(ChatMessageModel) onMessage) {
    _subscribers[matchId] = onMessage;
    if (_client?.connected == true) {
      _subscribeToMatch(matchId);
    }
  }

  void _subscribeToMatch(int matchId) {
    final unsubscribe = _client?.subscribe(
      destination: '/topic/chat/$matchId',
      callback: (frame) {
        if (frame.body != null) {
          final msg = ChatMessageModel.fromJson(
              jsonDecode(frame.body!) as Map<String, dynamic>);
          _subscribers[matchId]?.call(msg);
        }
      },
    );
    if (unsubscribe != null) _unsubscribers[matchId] = unsubscribe;
  }

  void unsubscribeFromChat(int matchId) {
    _subscribers.remove(matchId);
    _unsubscribers.remove(matchId)?.call();
  }

  void sendMessage(int matchId, String content) {
    _client?.send(
      destination: '/app/chat.send/$matchId',
      body: jsonEncode({
        'content': content,
        'messageType': 'TEXT',
        'sentAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _subscribers.clear();
    _unsubscribers.clear();
  }
}
