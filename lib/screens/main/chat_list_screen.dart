import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) await context.read<ChatProvider>().loadConversations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Messages',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
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
              child: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: chat.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : chat.conversations.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.conversations.length,
                    itemBuilder: (ctx, i) =>
                        _ConversationTile(conv: chat.conversations[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text('No messages yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Match with someone to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  const _ConversationTile({required this.conv});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.day == now.day) return DateFormat('HH:mm').format(dt);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = conv.otherUserName.isNotEmpty
        ? conv.otherUserName[0].toUpperCase()
        : '?';
    final timeStr = _formatTime(conv.lastMessageAt);

    return GestureDetector(
      onTap: () => context.push(
        '/chat/${conv.matchId}?name=${Uri.encodeComponent(conv.otherUserName)}',
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.25),
                        AppColors.primaryLight.withValues(alpha: 0.15),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.likeGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(conv.otherUserName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      const Spacer(),
                      Text(timeStr,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'Start a conversation!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${conv.matchScore.toInt()}%',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
