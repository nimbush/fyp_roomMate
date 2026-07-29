import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/otp_verify_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/main/discovery_screen.dart';
import '../screens/main/matches_screen.dart';
import '../screens/main/chat_list_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/static_content_screen.dart';
import '../screens/settings/support_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (ctx, state) => const RegisterScreen()),
    GoRoute(
        path: '/verify-otp',
        builder: (ctx, state) => const OtpVerifyScreen()),
    GoRoute(
        path: '/forgot-password',
        builder: (ctx, state) => const ForgotPasswordScreen()),
    GoRoute(
        path: '/reset-password',
        builder: (ctx, state) => const ResetPasswordScreen()),
    GoRoute(
        path: '/edit-profile',
        builder: (ctx, state) => const EditProfileScreen()),
    GoRoute(
        path: '/settings',
        builder: (ctx, state) => const SettingsScreen()),
    GoRoute(
      path: '/content/:service',
      builder: (ctx, state) =>
          StaticContentScreen(service: state.pathParameters['service']!),
    ),
    GoRoute(
        path: '/support', builder: (ctx, state) => const SupportScreen()),
    GoRoute(
      path: '/chat/:matchId',
      builder: (ctx, state) {
        final matchId = int.parse(state.pathParameters['matchId']!);
        final name =
            state.uri.queryParameters['name'] ?? 'Roommate';
        return ChatScreen(matchId: matchId, otherUserName: name);
      },
    ),

    // Main shell with bottom nav
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/home',
              builder: (ctx, state) => const DiscoveryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/matches',
              builder: (ctx, state) => const MatchesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/chats',
              builder: (ctx, state) => const ChatListScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/profile',
              builder: (ctx, state) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
