import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController()..load(),
);

/// Holds the user's Light / Dark / System preference and persists it.
///
/// The choice has to survive a restart - a theme that silently resets to light
/// every launch reads as the toggle being broken.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  static const _key = 'theme_mode';

  /// Resolves the mode against the platform brightness.
  ///
  /// Takes the platform value explicitly rather than reading
  /// `PlatformDispatcher` here, so the caller passes the same `MediaQuery`
  /// value the widget tree is rebuilding against and the two can't disagree.
  bool isDark(Brightness platformBrightness) => switch (state) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system => platformBrightness == Brightness.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = switch (prefs.getString(_key)) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    });
  }
}
