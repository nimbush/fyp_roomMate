import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/chat_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final int matchId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatProvider>().loadMessages(widget.matchId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().leaveChat(widget.matchId);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(widget.matchId, text);
    _msgCtrl.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currentUserId = context.read<AuthProvider>().userId ?? 0;
    final messages = chat.getMessages(widget.matchId);
    final initials = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primaryLight.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: AppColors.likeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Text('Online',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.likeGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('👋',
                                  style: TextStyle(fontSize: 40)),
                            ),
                            const SizedBox(height: 16),
                            const Text('Say hello!',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            const Text('Start the conversation',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final showDate = i == 0 ||
                              _shouldShowDate(messages[i - 1], messages[i]);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(messages[i].sentAt),
                              _MessageBubble(
                                message: messages[i],
                                isMine: messages[i].senderId == currentUserId,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _InputBar(controller: _msgCtrl, onSend: _send),
        ],
      ),
    );
  }

  bool _shouldShowDate(ChatMessageModel prev, ChatMessageModel curr) {
    if (prev.sentAt == null || curr.sentAt == null) return false;
    try {
      final a = DateTime.parse(prev.sentAt!);
      final b = DateTime.parse(curr.sentAt!);
      return a.day != b.day;
    } catch (_) {
      return false;
    }
  }
}

class _DateDivider extends StatelessWidget {
  final String? iso;
  const _DateDivider(this.iso);

  String _label() {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso!);
      final now = DateTime.now();
      if (dt.day == now.day) return 'Today';
      if (dt.day == now.subtract(const Duration(days: 1)).day) return 'Yesterday';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(_label(),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: 6,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName?.isNotEmpty == true
                      ? message.senderName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine ? AppColors.primaryGradient : null,
                color: isMine ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _hasText ? AppColors.primaryGradient : null,
              color: _hasText ? null : AppColors.surface,
              shape: BoxShape.circle,
              border: _hasText
                  ? null
                  : Border.all(color: AppColors.border),
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: _hasText ? widget.onSend : null,
              icon: Icon(
                Icons.send_rounded,
                color: _hasText ? Colors.white : AppColors.textHint,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
