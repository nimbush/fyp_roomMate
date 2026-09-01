import 'package:flutter/material.dart';

/// Liquid Glass design tokens (see DESIGN.md).
///
/// Every mode-varying token is a **getter**, not a `const` - Dart consts can't
/// branch on the active theme, so the whole palette has to be resolved at read
/// time.
///
/// Never store one of these in a `const` expression or a `static final`; read it
/// inside `build`, or the value freezes at whatever mode was active when the
/// expression was first evaluated.
class AppColors {
  AppColors._();

  /// Set at app root before every build, from the persisted theme preference.
  static bool _isDark = false;

  static bool get isDark => _isDark;

  static void setDarkMode(bool value) => _isDark = value;

  // ---------------------------------------------------------------- brand ----

  /// Brand orange.
  ///
  /// Dark keeps the same hue rather than the old washed-out salmon (#FF8C61),
  /// which read as a different, weaker brand. It's lifted only slightly, because
  /// the full-saturation light value vibrates against a near-black canvas.
  static Color get primary =>
      _isDark ? const Color(0xFFFF7A45) : const Color(0xFFFF6B35);
  static Color get primaryLight => const Color(0xFFFF8C61);
  static Color get primaryDark => const Color(0xFFE5521A);

  /// Foreground on accent surfaces (chips, pills, selected tabs).
  ///
  /// A warm near-white in dark: pure white on an orange-tinted fill looks
  /// clinical, and full orange on a dark orange fill has too little contrast.
  static Color get accentInk =>
      _isDark ? const Color(0xFFFFD9C7) : const Color(0xFFFF6B35);

  /// Ring around accent surfaces. Transparent in light so the frost stays clean.
  static Color get accentRing =>
      _isDark ? primary.withValues(alpha: 0.40) : Colors.transparent;

  /// Accent fill.
  ///
  /// Much lighter in dark than it was (20%): orange at that strength over black
  /// turns into an opaque muddy brown instead of a tint.
  static Color get primarySoft =>
      primary.withValues(alpha: _isDark ? 0.14 : 0.08);

  // --------------------------------------------------------------- canvas ----

  static Color get scaffoldBackground =>
      _isDark ? const Color(0xFF101114) : const Color(0xFFF6F6F7);

  // The backdrop is a near-flat neutral ramp, not a visible gradient. An earlier
  // version ran white -> #F2F1F4 in light and mixed a violet bloom with the
  // orange one; the warm/cool clash and the contrast under the cards made the
  // page tiring to look at. These three steps are close enough together to read
  // as one calm surface.
  static Color get backdropTop =>
      _isDark ? const Color(0xFF121317) : const Color(0xFFFAFAFB);
  static Color get backdropMid =>
      _isDark ? const Color(0xFF101115) : const Color(0xFFF6F6F7);
  static Color get backdropBottom =>
      _isDark ? const Color(0xFF0E0F12) : const Color(0xFFF1F1F3);

  /// Ambient blooms behind the glass.
  ///
  /// Single warm family - all three are the brand hue at low alpha, so the page
  /// reads as one tinted light source rather than two competing ones. Kept faint
  /// deliberately: the blooms are atmosphere, and anything stronger competes
  /// with the content sitting on top of them.
  static Color get bloomA => primary.withValues(alpha: _isDark ? 0.05 : 0.05);
  static Color get bloomB =>
      const Color(0xFFFF8C61).withValues(alpha: _isDark ? 0.035 : 0.035);
  static Color get bloomC =>
      const Color(0xFFFFA07A).withValues(alpha: _isDark ? 0.02 : 0.025);

  // ---------------------------------------------------------------- glass ----

  // Dark surfaces are solid greys, not translucent white.
  //
  // Translucent white over a near-black canvas tops out around 6-10% before it
  // starts looking hazy, which is nowhere near enough to separate a card from
  // the page - the cards read as flat black with a faint outline. Solid values
  // stepping up from the canvas give a real elevation ramp, which is how every
  // legible dark theme does it.
  static Color get glassFill => _isDark
      ? const Color(0xFF1C1D22)
      : Colors.white.withValues(alpha: 0.72);
  static Color get glassFillStrong => _isDark
      ? const Color(0xFF23242A)
      : Colors.white.withValues(alpha: 0.88);
  static Color get glassFillSubtle => _isDark
      ? const Color(0xFF17181C)
      : Colors.white.withValues(alpha: 0.55);

  /// Fill for surfaces whose whole point is the blur showing through - the
  /// floating nav bar, frosted app bars.
  ///
  /// Deliberately much lighter than `glassFillStrong`: at 88% opacity the fill
  /// paints over the `BackdropFilter` and the frost is invisible, leaving what
  /// looks like a plain white bar. This keeps enough tint for text contrast
  /// while the content underneath still reads as blurred.
  ///
  /// Must stay translucent for the blur to read at all, so in dark it's a
  /// lightened surface grey at high alpha rather than white at low alpha -
  /// white that faint simply disappears against the canvas.
  static Color get glassFillFrosted => _isDark
      ? const Color(0xFF23242A).withValues(alpha: 0.82)
      : Colors.white.withValues(alpha: 0.45);

  /// Hairline edge on cards and dividers.
  ///
  /// Stronger in both modes than the usual 6%: the calm backdrop sits close to
  /// the card fill, so a fainter line leaves cards without a readable edge.
  static Color get glassBorderInk => _isDark
      ? Colors.white.withValues(alpha: 0.13)
      : Colors.black.withValues(alpha: 0.08);

  static Color get glassHighlight => Colors.white.withValues(alpha: 0.65);

  static Color get glassShadow =>
      Colors.black.withValues(alpha: _isDark ? 0.55 : 0.10);
  static Color get glassShadowSoft =>
      Colors.black.withValues(alpha: _isDark ? 0.40 : 0.05);

  /// Solid dialog/sheet/card background. Translucent fills vanish on the dark
  /// canvas, so these deliberately opt out of glass.
  ///
  /// Sits a step above `glassFill` so a dialog reads as floating above the card
  /// it was opened from.
  static Color get surfaceColor =>
      _isDark ? const Color(0xFF1C1D22) : const Color(0xFFFFFFFF);

  // ----------------------------------------------------------------- text ----

  static Color get textInk =>
      _isDark ? const Color(0xFFF2F1F4) : const Color(0xFF1A1A1A);
  static Color get textMuted =>
      _isDark ? const Color(0xFFA0A0A8) : const Color(0xFF666666);
  static Color get textFaint =>
      _isDark ? const Color(0xFF6C6C74) : const Color(0xFFAAAAAA);

  // --------------------------------------------------------------- status ----

  // Status colours keep their meaning in both modes - a red error must still
  // read as an error - but the dark variants are lifted and desaturated.
  // Full-saturation mid-tones vibrate against a near-black canvas, which is what
  // made the dark theme feel harsh.
  static Color get success =>
      _isDark ? const Color(0xFF6FCF7C) : const Color(0xFF4CAF50);
  static Color get error =>
      _isDark ? const Color(0xFFFF6B60) : const Color(0xFFF44336);
  static Color get warning =>
      _isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
  static Color get likeGreen =>
      _isDark ? const Color(0xFF6FCF7C) : const Color(0xFF4CAF50);
  static Color get passRed =>
      _isDark ? const Color(0xFFFF7A70) : const Color(0xFFFF5252);

  /// Secondary category accents used on profile sections and stat tiles.
  ///
  /// Screens previously hardcoded `0xFF7C3AED` / `0xFF059669`, which are far too
  /// saturated for a dark canvas. Read these instead of literals.
  static Color get accentViolet =>
      _isDark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED);
  static Color get accentTeal =>
      _isDark ? const Color(0xFF5EC9A0) : const Color(0xFF059669);

  // ------------------------------------------------------------ gradients ----

  /// In dark the ramp runs deeper rather than lighter: fading toward the pale
  /// `primaryLight` on a black canvas is what made buttons look washed-out
  /// salmon instead of brand orange.
  static LinearGradient get primaryGradient => LinearGradient(
        colors: _isDark
            ? [const Color(0xFFFF7A45), const Color(0xFFF25C2A)]
            : [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Scrim over deck-card photography so overlaid text stays legible.
  static LinearGradient get cardGradient => const LinearGradient(
        colors: [Colors.transparent, Color(0xCC000000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ------------------------------------------------- legacy aliases ----------
  // The pre-Liquid-Glass names, kept so unmigrated screens keep compiling while
  // the system is adopted incrementally (DESIGN.md: "existing screens migrate
  // when touched"). Prefer the tokens above in new code.

  static Color get background => backdropTop;
  static Color get surface => scaffoldBackground;
  static Color get cardBackground => surfaceColor;
  static Color get textPrimary => textInk;
  static Color get textSecondary => textMuted;
  static Color get textHint => textFaint;
  static Color get divider => glassBorderInk;
  static Color get border => _isDark ? glassBorderInk : const Color(0xFFDDDDDD);
  static Color get chatBubbleSent => primary;
  static Color get chatBubbleReceived =>
      _isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F0F0);
}
