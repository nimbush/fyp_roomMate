import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../models/match_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) await context.read<MatchProvider>().loadMatches(userId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<MatchProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Matches',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Matched  ${matches.accepted.isEmpty ? '' : '(${matches.accepted.length})'}'),
                Tab(text: 'Pending  ${matches.pending.isEmpty ? '' : '(${matches.pending.length})'}'),
              ],
            ),
          ),
        ),
      ),
      body: matches.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _AcceptedList(matches: matches.accepted),
                _PendingList(pending: matches.pending),
              ],
            ),
    );
  }
}

// ── Accepted ──────────────────────────────────────────────────────────────────

class _AcceptedList extends StatelessWidget {
  final List<MatchModel> matches;
  const _AcceptedList({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('No matches yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Start swiping to find\nyour perfect roommate!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final userId = context.read<AuthProvider>().userId;
        if (userId != null) await context.read<MatchProvider>().loadMatches(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matches.length,
        itemBuilder: (ctx, i) => _MatchCard(match: matches[i]),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId ?? 0;
    final otherId = match.otherUserId(currentUserId);
    final score = match.matchScore.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with score ring
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primaryLight.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 32),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      '$score%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User #$otherId',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.likeGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Matched',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push(
                  '/chat/${match.id}?name=User+%23$otherId'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_rounded,
                        size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text('Chat',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending ───────────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  final List<MatchModel> pending;
  const _PendingList({required this.pending});

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 56, color: AppColors.warning),
            ),
            const SizedBox(height: 20),
            const Text('No pending requests',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('When someone likes you back,\nthey\'ll appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (ctx, i) => _PendingCard(match: pending[i]),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final MatchModel match;
  const _PendingCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId ?? 0;
    final otherId = match.otherUserId(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.warning, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User #$otherId',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${match.matchScore.toInt()}% compatible',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Row(
              children: [
                _CircleAction(
                  icon: Icons.close_rounded,
                  color: AppColors.passRed,
                  onTap: () =>
                      context.read<MatchProvider>().rejectMatch(match.id),
                ),
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.check_rounded,
                  color: AppColors.likeGreen,
                  onTap: () =>
                      context.read<MatchProvider>().acceptMatch(match.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleAction(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
