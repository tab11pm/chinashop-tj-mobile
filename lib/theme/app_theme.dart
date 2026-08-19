import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Canonical font families bundled in pubspec.yaml (full Cyrillic — tj/ru).
/// Body/UI ramp → Manrope, heading/chrome/tracking ramp → Onest,
/// numeric/price ramp → Nunito (UI-SPEC Typography, D-03/D-04a).
const String _fontBody = 'Manrope';
const String _fontHeading = 'Onest';
const String _fontNumeric = 'Nunito';

/// CreamTokens — ThemeExtension carrying roles Material3 has no slot for:
/// the cream surface split (scaffold bg vs card), the Nunito price TextStyle,
/// and the tracking-node colors (green done-glow / current pulse-ring).
///
/// Screen code reads these via `Theme.of(context).extension<CreamTokens>()!`.
@immutable
class CreamTokens extends ThemeExtension<CreamTokens> {
  /// Scaffold (page) background — cream.
  final Color scaffoldBg;

  /// Card / elevated surface — lighter cream (never pure #fff).
  final Color cardSurface;

  /// Hairline border between cream surfaces.
  final Color hairline;

  /// Canonical price text style (Nunito 900) — Material3 has no price slot.
  final TextStyle priceStyle;

  /// Tracking node — "done" green glow color.
  final Color trackDoneGlow;

  /// Tracking node — "current" pulse ring color.
  final Color trackPulseRing;

  const CreamTokens({
    required this.scaffoldBg,
    required this.cardSurface,
    required this.hairline,
    required this.priceStyle,
    required this.trackDoneGlow,
    required this.trackPulseRing,
  });

  @override
  CreamTokens copyWith({
    Color? scaffoldBg,
    Color? cardSurface,
    Color? hairline,
    TextStyle? priceStyle,
    Color? trackDoneGlow,
    Color? trackPulseRing,
  }) {
    return CreamTokens(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      cardSurface: cardSurface ?? this.cardSurface,
      hairline: hairline ?? this.hairline,
      priceStyle: priceStyle ?? this.priceStyle,
      trackDoneGlow: trackDoneGlow ?? this.trackDoneGlow,
      trackPulseRing: trackPulseRing ?? this.trackPulseRing,
    );
  }

  @override
  CreamTokens lerp(ThemeExtension<CreamTokens>? other, double t) {
    if (other is! CreamTokens) return this;
    return CreamTokens(
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      priceStyle: TextStyle.lerp(priceStyle, other.priceStyle, t)!,
      trackDoneGlow: Color.lerp(trackDoneGlow, other.trackDoneGlow, t)!,
      trackPulseRing: Color.lerp(trackPulseRing, other.trackPulseRing, t)!,
    );
  }
}

/// ChinaShop TJ house theme — assembled from design tokens (app_tokens.dart).
/// Cream client surface, green accent, soft elevation, ease-out motion,
/// 3-font ramp (Manrope body / Onest heading / Nunito price).
ThemeData getAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accentHover,
    onSecondary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: AppColors.onAccent,
    brightness: Brightness.light,
  );

  RoundedRectangleBorder rr(double r, {BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r), side: side);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,

    // Client cream "storybook" has no full-bleed green bar (D-07 / UI-SPEC
    // Elevation): appbar is the cream surface with ink foreground.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _fontHeading,
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: AppColors.ink),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1.5,
      shadowColor: AppColors.ink.withValues(alpha: 0.10),
      shape: rr(AppRadii.card, side: const BorderSide(color: AppColors.line)),
      margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      clipBehavior: Clip.antiAlias,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return AppColors.line;
          if (s.contains(WidgetState.pressed)) return AppColors.accentHover;
          return AppColors.accent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.disabled)
                ? AppColors.inkFaint
                : AppColors.onAccent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.lg),
        ),
        shape: WidgetStatePropertyAll(rr(AppRadii.control)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        animationDuration: AppMotion.tap,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentDeep,
        side: const BorderSide(color: AppColors.accentBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl, vertical: AppSpace.lg),
        shape: rr(AppRadii.control),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentHover,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.lg),
      hintStyle: const TextStyle(color: AppColors.inkFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accentPlate,
      checkmarkColor: AppColors.accentDeep,
      labelStyle: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
      secondaryLabelStyle:
          const TextStyle(fontSize: 13, color: AppColors.accentDeep),
      side: const BorderSide(color: AppColors.line),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.onAccent,
      elevation: 2,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.inkFaint,
      backgroundColor: AppColors.surface,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: AppColors.onAccent),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control)),
    ),

    dividerTheme: const DividerThemeData(
        color: AppColors.line, thickness: 1, space: 0),

    // Type scale per UI-SPEC Typography. Heading ramp → Onest, body/label
    // ramp → Manrope. Long tj/ru strings: line-height ≥ 1.3 on body/headings.
    textTheme: const TextTheme(
      // Heading ramp (Onest).
      displaySmall: TextStyle(
          fontFamily: _fontHeading,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          height: 1.2,
          color: AppColors.ink),
      headlineMedium: TextStyle(
          fontFamily: _fontHeading,
          fontWeight: FontWeight.w600,
          fontSize: 21,
          height: 1.3,
          color: AppColors.ink),
      headlineSmall: TextStyle(
          fontFamily: _fontHeading,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.3,
          color: AppColors.ink),
      // Title is body ramp (Manrope) per UI-SPEC.
      titleLarge: TextStyle(
          fontFamily: _fontBody,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          height: 1.3,
          color: AppColors.ink),
      titleMedium: TextStyle(
          fontFamily: _fontBody,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          height: 1.3,
          color: AppColors.ink),
      // Body ramp (Manrope).
      bodyLarge: TextStyle(
          fontFamily: _fontBody,
          fontSize: 15,
          height: 1.5,
          color: AppColors.ink),
      bodyMedium: TextStyle(
          fontFamily: _fontBody,
          fontSize: 13,
          height: 1.5,
          color: AppColors.inkMuted),
      // Label / caption ramp (Manrope).
      labelLarge: TextStyle(
          fontFamily: _fontBody,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.onAccent),
    ),

    extensions: const <ThemeExtension<dynamic>>[
      CreamTokens(
        scaffoldBg: AppColors.bg,
        cardSurface: AppColors.surface,
        hairline: AppColors.line,
        // Price (default) — Nunito 900, UI-SPEC Numeric ramp.
        priceStyle: TextStyle(
          fontFamily: _fontNumeric,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          height: 1.1,
          letterSpacing: -0.2,
          color: AppColors.accentDeep,
        ),
        trackDoneGlow: AppColors.accent,
        trackPulseRing: AppColors.accentBorder,
      ),
    ],

    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    }),
  );
}
