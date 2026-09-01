import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:roommate_finder/common/utils/session_manager.dart';
import 'package:roommate_finder/config/app_colors.dart';
import 'package:roommate_finder/config/app_theme.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/controller/theme_controller.dart';
import 'package:roommate_finder/features/auth/controller/auth_controller.dart';
import 'package:roommate_finder/features/profile/controller/profile_controller.dart';
import 'package:roommate_finder/route/route_manager.dart';

/// Lets the session listener show a snackbar without a screen `BuildContext`.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const ProviderScope(child: RoomMateFinderApp()));
}

class RoomMateFinderApp extends StatelessWidget {
  const RoomMateFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Reference frame the .sp/.w/.h/.r units scale from.
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => const _ThemedApp(),
    );
  }
}

class _ThemedApp extends ConsumerWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    final isDark = ref
        .read(themeControllerProvider.notifier)
        .isDark(MediaQuery.platformBrightnessOf(context));

    // Must run before the subtree builds: every AppColors token is a getter
    // reading this flag, so setting it late would paint one frame in the old
    // palette.
    AppColors.setDarkMode(isDark);

    return _SessionGate(
      // Remounting on toggle forces every widget holding a resolved colour to
      // rebuild from scratch. Screen-local state resets by design; GoRouter
      // keeps the current location, so the user stays where they were.
      child: KeyedSubtree(
        key: ValueKey(isDark),
        child: MaterialApp.router(
          title: 'RoomMate Finder',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          // Both themes are supplied so Flutter can pick per themeMode, but
          // AppColors has already resolved the palette either way.
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}

/// Sends the user back to sign-in whenever the API reports an expired session.
///
/// This lives above `MaterialApp.router` so a 401 from any screen is handled in
/// one place; individual screens don't each need their own expiry branch.
class _SessionGate extends ConsumerStatefulWidget {
  const _SessionGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<_SessionGate> {
  // Cached in initState because `ref` must not be touched from dispose().
  late final SessionManager _session;

  @override
  void initState() {
    super.initState();
    _session = ref.read(sessionManagerProvider);
    _session.expired.addListener(_onExpired);
  }

  @override
  void dispose() {
    _session.expired.removeListener(_onExpired);
    super.dispose();
  }

  Future<void> _onExpired() async {
    // Clear the dead token before navigating, so the splash route cannot bounce
    // the user straight back to /home on the next launch.
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    ref.read(profileControllerProvider.notifier).clear();

    appRouter.go('/login');
    ref.read(sessionManagerProvider).reset();

    final messenger = scaffoldMessengerKey.currentState;
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Your session expired. Please sign in again.'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
