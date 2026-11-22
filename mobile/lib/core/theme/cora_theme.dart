import 'package:flutter/material.dart';

/// Semantic foreground/background color pair for cycle phases and clinical badges.
@immutable
class CoraPhaseColorPair {
  final Color foreground;
  final Color background;
  final Color border;

  const CoraPhaseColorPair({
    required this.foreground,
    required this.background,
    required this.border,
  });
}

/// Design tokens for Cora v2.0 (Warm Botanical Health Editorial + WCAG AAA).
@immutable
class CoraColorTokens extends ThemeExtension<CoraColorTokens> {
  final Color canvas;
  final Color surface;
  final Color surfaceSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderSubtle;
  final Color accentPrimary;
  final Color accentSurface;
  final Color menstrual;
  final Color menstrualSurface;
  final Color follicular;
  final Color follicularSurface;
  final Color ovulatory;
  final Color ovulatorySurface;
  final Color luteal;
  final Color lutealSurface;
  final Color hormonal;
  final Color hormonalSurface;
  final Color alertPreventive;
  final Color alertPreventiveSurface;
  final Color alertUrgent;
  final Color alertUrgentSurface;
  final Color primaryDeep;
  final Color blushInset;
  final Color verified;
  final Color verifiedSurface;
  final Color verifiedMint;
  final bool isHighLegibility;

  const CoraColorTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderSubtle,
    required this.accentPrimary,
    required this.accentSurface,
    required this.menstrual,
    required this.menstrualSurface,
    required this.follicular,
    required this.follicularSurface,
    required this.ovulatory,
    required this.ovulatorySurface,
    required this.luteal,
    required this.lutealSurface,
    required this.hormonal,
    required this.hormonalSurface,
    required this.alertPreventive,
    required this.alertPreventiveSurface,
    required this.alertUrgent,
    required this.alertUrgentSurface,
    this.primaryDeep = const Color(0xFF93204B),
    this.blushInset = const Color(0xFFFFF0F4),
    this.verified = const Color(0xFF006B57),
    this.verifiedSurface = const Color(0xFFDDF7EE),
    this.verifiedMint = const Color(0xFF9EF3D9),
    required this.isHighLegibility,
  });

  static const CoraColorTokens standard = CoraColorTokens(
    canvas: Color(0xFFFBF8F6),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF4ECE8),
    textPrimary: Color(0xFF241A1E),
    textSecondary: Color(0xFF67585F),
    borderSubtle: Color(0xFFE9DCD6),
    accentPrimary: Color(0xFFB33A63),
    accentSurface: Color(0xFFFCEBF1),
    menstrual: Color(0xFFBD2E4E),
    menstrualSurface: Color(0xFFFDECEF),
    follicular: Color(0xFF9E531E),
    follicularSurface: Color(0xFFFDF3EA),
    ovulatory: Color(0xFF1A6E5B),
    ovulatorySurface: Color(0xFFE8F6F2),
    luteal: Color(0xFF5B457E),
    lutealSurface: Color(0xFFF2EEF9),
    hormonal: Color(0xFF35566E),
    hormonalSurface: Color(0xFFEDF4F8),
    alertPreventive: Color(0xFF9A4407),
    alertPreventiveSurface: Color(0xFFFEF3C7),
    alertUrgent: Color(0xFFB91C1C),
    alertUrgentSurface: Color(0xFFFEE2E2),
    primaryDeep: Color(0xFF93204B),
    blushInset: Color(0xFFFFF0F4),
    verified: Color(0xFF006B57),
    verifiedSurface: Color(0xFFDDF7EE),
    verifiedMint: Color(0xFF9EF3D9),
    isHighLegibility: false,
  );

  static const CoraColorTokens highLegibility = CoraColorTokens(
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFF2F2F2),
    textPrimary: Color(0xFF121212),
    textSecondary: Color(0xFF383838),
    borderSubtle: Color(0xFF1F1F1F),
    accentPrimary: Color(0xFF5C0A28),
    accentSurface: Color(0xFFFCEBF1),
    menstrual: Color(0xFF7A0B26),
    menstrualSurface: Color(0xFFFFF0F3),
    follicular: Color(0xFF6B3400),
    follicularSurface: Color(0xFFFFF6EB),
    ovulatory: Color(0xFF004D40),
    ovulatorySurface: Color(0xFFEBF8F5),
    luteal: Color(0xFF3B1F6B),
    lutealSurface: Color(0xFFF3EEFA),
    hormonal: Color(0xFF143A52),
    hormonalSurface: Color(0xFFEDF5FA),
    alertPreventive: Color(0xFF6B3100),
    alertPreventiveSurface: Color(0xFFFFF7DB),
    alertUrgent: Color(0xFF7F0000),
    alertUrgentSurface: Color(0xFFFFEBEB),
    primaryDeep: Color(0xFF5C0A28),
    blushInset: Color(0xFFF5F5F5),
    verified: Color(0xFF004D40),
    verifiedSurface: Color(0xFFEBF8F5),
    verifiedMint: Color(0xFFEBF8F5),
    isHighLegibility: true,
  );

  /// Returns calibrated foreground, background, and border colors for a phase key.
  CoraPhaseColorPair phaseColors(String phaseKey) {
    switch (phaseKey.toLowerCase()) {
      case 'menstrual':
        return CoraPhaseColorPair(
          foreground: menstrual,
          background: menstrualSurface,
          border: menstrual.withValues(alpha: isHighLegibility ? 1.0 : 0.28),
        );
      case 'follicular':
        return CoraPhaseColorPair(
          foreground: follicular,
          background: follicularSurface,
          border: follicular.withValues(alpha: isHighLegibility ? 1.0 : 0.28),
        );
      case 'ovulatory':
      case 'fertile':
        return CoraPhaseColorPair(
          foreground: ovulatory,
          background: ovulatorySurface,
          border: ovulatory.withValues(alpha: isHighLegibility ? 1.0 : 0.28),
        );
      case 'luteal':
        return CoraPhaseColorPair(
          foreground: luteal,
          background: lutealSurface,
          border: luteal.withValues(alpha: isHighLegibility ? 1.0 : 0.28),
        );
      case 'hormonally_managed':
      case 'hormonal':
        return CoraPhaseColorPair(
          foreground: hormonal,
          background: hormonalSurface,
          border: hormonal.withValues(alpha: isHighLegibility ? 1.0 : 0.28),
        );
      default:
        return CoraPhaseColorPair(
          foreground: accentPrimary,
          background: accentSurface,
          border:
              accentPrimary.withValues(alpha: isHighLegibility ? 1.0 : 0.25),
        );
    }
  }

  @override
  CoraColorTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderSubtle,
    Color? accentPrimary,
    Color? accentSurface,
    Color? menstrual,
    Color? menstrualSurface,
    Color? follicular,
    Color? follicularSurface,
    Color? ovulatory,
    Color? ovulatorySurface,
    Color? luteal,
    Color? lutealSurface,
    Color? hormonal,
    Color? hormonalSurface,
    Color? alertPreventive,
    Color? alertPreventiveSurface,
    Color? alertUrgent,
    Color? alertUrgentSurface,
    Color? primaryDeep,
    Color? blushInset,
    Color? verified,
    Color? verifiedSurface,
    Color? verifiedMint,
    bool? isHighLegibility,
  }) {
    return CoraColorTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSurface: accentSurface ?? this.accentSurface,
      menstrual: menstrual ?? this.menstrual,
      menstrualSurface: menstrualSurface ?? this.menstrualSurface,
      follicular: follicular ?? this.follicular,
      follicularSurface: follicularSurface ?? this.follicularSurface,
      ovulatory: ovulatory ?? this.ovulatory,
      ovulatorySurface: ovulatorySurface ?? this.ovulatorySurface,
      luteal: luteal ?? this.luteal,
      lutealSurface: lutealSurface ?? this.lutealSurface,
      hormonal: hormonal ?? this.hormonal,
      hormonalSurface: hormonalSurface ?? this.hormonalSurface,
      alertPreventive: alertPreventive ?? this.alertPreventive,
      alertPreventiveSurface:
          alertPreventiveSurface ?? this.alertPreventiveSurface,
      alertUrgent: alertUrgent ?? this.alertUrgent,
      alertUrgentSurface: alertUrgentSurface ?? this.alertUrgentSurface,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      blushInset: blushInset ?? this.blushInset,
      verified: verified ?? this.verified,
      verifiedSurface: verifiedSurface ?? this.verifiedSurface,
      verifiedMint: verifiedMint ?? this.verifiedMint,
      isHighLegibility: isHighLegibility ?? this.isHighLegibility,
    );
  }

  @override
  CoraColorTokens lerp(ThemeExtension<CoraColorTokens>? other, double t) {
    if (other is! CoraColorTokens) return this;
    return CoraColorTokens(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t) ??
              surfaceSecondary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      accentPrimary:
          Color.lerp(accentPrimary, other.accentPrimary, t) ?? accentPrimary,
      accentSurface:
          Color.lerp(accentSurface, other.accentSurface, t) ?? accentSurface,
      menstrual: Color.lerp(menstrual, other.menstrual, t) ?? menstrual,
      menstrualSurface:
          Color.lerp(menstrualSurface, other.menstrualSurface, t) ??
              menstrualSurface,
      follicular: Color.lerp(follicular, other.follicular, t) ?? follicular,
      follicularSurface:
          Color.lerp(follicularSurface, other.follicularSurface, t) ??
              follicularSurface,
      ovulatory: Color.lerp(ovulatory, other.ovulatory, t) ?? ovulatory,
      ovulatorySurface:
          Color.lerp(ovulatorySurface, other.ovulatorySurface, t) ??
              ovulatorySurface,
      luteal: Color.lerp(luteal, other.luteal, t) ?? luteal,
      lutealSurface:
          Color.lerp(lutealSurface, other.lutealSurface, t) ?? lutealSurface,
      hormonal: Color.lerp(hormonal, other.hormonal, t) ?? hormonal,
      hormonalSurface: Color.lerp(hormonalSurface, other.hormonalSurface, t) ??
          hormonalSurface,
      alertPreventive: Color.lerp(alertPreventive, other.alertPreventive, t) ??
          alertPreventive,
      alertPreventiveSurface:
          Color.lerp(alertPreventiveSurface, other.alertPreventiveSurface, t) ??
              alertPreventiveSurface,
      alertUrgent: Color.lerp(alertUrgent, other.alertUrgent, t) ?? alertUrgent,
      alertUrgentSurface:
          Color.lerp(alertUrgentSurface, other.alertUrgentSurface, t) ??
              alertUrgentSurface,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t) ?? primaryDeep,
      blushInset: Color.lerp(blushInset, other.blushInset, t) ?? blushInset,
      verified: Color.lerp(verified, other.verified, t) ?? verified,
      verifiedSurface: Color.lerp(verifiedSurface, other.verifiedSurface, t) ??
          verifiedSurface,
      verifiedMint:
          Color.lerp(verifiedMint, other.verifiedMint, t) ?? verifiedMint,
      isHighLegibility: t < 0.5 ? isHighLegibility : other.isHighLegibility,
    );
  }
}

class CoraTheme {
  // Standard Empathetic Health Palette (Cora v2.0 — Warm Botanical Editorial)
  static const Color primaryColor = Color(0xFFB33A63);
  static const Color secondaryColor = Color(0xFF1A6E5B);
  static const Color surfaceColor = Color(0xFFFBF8F6);
  static const Color textColor = Color(0xFF241A1E);

  // High Legibility (WCAG AAA >= 7:1) Palette for Senior Vitality
  static const Color highLegibilityPrimary = Color(0xFF5C0A28);
  static const Color highLegibilityText = Color(0xFF121212);
  static const Color highLegibilityBackground = Color(0xFFFFFFFF);
  static const Color highLegibilityBorder = Color(0xFF1F1F1F);

  /// Safe accessor for [CoraColorTokens] with fallback to [CoraColorTokens.standard].
  static CoraColorTokens tokensOf(BuildContext context) {
    return Theme.of(context).extension<CoraColorTokens>() ??
        CoraColorTokens.standard;
  }

  static ThemeData standard() {
    const tokens = CoraColorTokens.standard;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: tokens.accentPrimary,
      brightness: Brightness.light,
      primary: tokens.accentPrimary,
      onPrimary: Colors.white,
      secondary: tokens.ovulatory,
      onSecondary: Colors.white,
      surface: tokens.canvas,
      onSurface: tokens.textPrimary,
      surfaceContainerLowest: tokens.surface,
      surfaceContainerLow: tokens.canvas,
      surfaceContainer: tokens.surfaceSecondary,
      outline: tokens.borderSubtle,
      error: tokens.alertUrgent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          color: tokens.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          color: tokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: tokens.textSecondary,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tokens.accentPrimary, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primaryDeep,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return tokens.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primaryDeep;
          return tokens.borderSubtle;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primaryDeep;
          return Colors.transparent;
        }),
        side: BorderSide(
          color: tokens.textSecondary.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
    );
  }

  static ThemeData highLegibility() {
    const tokens = CoraColorTokens.highLegibility;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tokens.canvas,
      extensions: const <ThemeExtension<dynamic>>[tokens],
      colorScheme: ColorScheme.light(
        primary: tokens.accentPrimary,
        onPrimary: Colors.white,
        secondary: tokens.ovulatory,
        onSecondary: Colors.white,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        outline: tokens.borderSubtle,
        error: tokens.alertUrgent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.borderSubtle, width: 2),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          color: tokens.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: tokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: tokens.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: tokens.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: tokens.borderSubtle, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accentPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(56, 56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: tokens.borderSubtle, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
