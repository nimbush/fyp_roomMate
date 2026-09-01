import 'package:go_router/go_router.dart';
import 'package:roommate_finder/features/splash/view/splash_screen.dart';
import 'package:roommate_finder/features/auth/view/login_screen.dart';
import 'package:roommate_finder/features/auth/view/register_screen.dart';
import 'package:roommate_finder/features/auth/view/otp_verify_screen.dart';
import 'package:roommate_finder/features/auth/view/forgot_password_screen.dart';
import 'package:roommate_finder/features/auth/view/reset_password_screen.dart';
import 'package:roommate_finder/features/home/view/main_shell.dart';
import 'package:roommate_finder/features/discovery/view/discovery_screen.dart';
import 'package:roommate_finder/features/matches/view/matches_screen.dart';
import 'package:roommate_finder/features/chat/view/chat_list_screen.dart';
import 'package:roommate_finder/features/profile/view/profile_screen.dart';
import 'package:roommate_finder/features/chat/view/chat_screen.dart';
import 'package:roommate_finder/features/profile/view/edit_profile_screen.dart';
import 'package:roommate_finder/features/settings/view/faq_screen.dart';
import 'package:roommate_finder/features/settings/view/settings_screen.dart';
import 'package:roommate_finder/features/settings/view/static_content_screen.dart';
import 'package:roommate_finder/features/settings/view/support_screen.dart';

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
    // FAQ has its own accordion screen rather than the generic content dump.
    GoRoute(path: '/faq', builder: (ctx, state) => const FaqScreen()),
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
