import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roommate_finder/common/widgets/glass_bottom_nav.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent: each branch screen brings its own GlassScaffold backdrop,
      // and the nav bar floats over it.
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: navigationShell.currentIndex,
        items: kMainNavItems,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

