import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../models/chat_message_model.dart';

class WebSocketService {
  StompClient? _client;
  final Map<int, Function(ChatMessageModel)> _subscribers = {};

  void connect(String token) {
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
    for (final matchId in List<int>.from(_subscribers.keys)) {
      _subscribeToMatch(matchId);
    }
  }

  void subscribeToChat(int matchId, Function(ChatMessageModel) onMessage) {
    _subscribers[matchId] = onMessage;
    if (_client?.connected == true) {
      _subscribeToMatch(matchId);
    }
  }

  void _subscribeToMatch(int matchId) {
    _client?.subscribe(
      destination: '/topic/chat/$matchId',
      callback: (frame) {
        if (frame.body != null) {
          final msg = ChatMessageModel.fromJson(
              jsonDecode(frame.body!) as Map<String, dynamic>);
          _subscribers[matchId]?.call(msg);
        }
      },
    );
  }

  void unsubscribeFromChat(int matchId) {
    _subscribers.remove(matchId);
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
    _subscribers.clear();
  }
}
