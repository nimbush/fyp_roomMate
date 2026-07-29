import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/discovery_provider.dart';
import 'providers/match_provider.dart';
import 'providers/profile_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const RoomMateFinderApp());
}

class RoomMateFinderApp extends StatelessWidget {
  const RoomMateFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp.router(
        title: 'RoomMate Finder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
