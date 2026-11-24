import 'package:flutter/material.dart';

/// Semantic design tokens for cloneGPT's strict 2-color enterprise design system.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color background;
  final Color surface;
  final Color inkPrimary;
  final Color inkMuted;
  final Color border;
  final Color accent;
  final Color destructive;

  const AppCustomColors({
    required this.background,
    required this.surface,
    required this.inkPrimary,
    required this.inkMuted,
    required this.border,
    required this.accent,
    required this.destructive,
  });

  static const light = AppCustomColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F5),
    inkPrimary: Color(0xFF09090B),
    inkMuted: Color(0xFF71717A),
    border: Color(0xFFE4E4E7),
    accent: Color(0xFF18181B),
    destructive: Color(0xFFDC2626),
  );

  static const dark = AppCustomColors(
    background: Color(0xFF09090B),
    surface: Color(0xFF141417),
    inkPrimary: Color(0xFFFAFAFA),
    inkMuted: Color(0xFFA1A1AA),
    border: Color(0xFF27272A),
    accent: Color(0xFFFAFAFA),
    destructive: Color(0xFFDC2626),
  );

  @override
  AppCustomColors copyWith({
    Color? background,
    Color? surface,
    Color? inkPrimary,
    Color? inkMuted,
    Color? border,
    Color? accent,
    Color? destructive,
  }) {
    return AppCustomColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkMuted: inkMuted ?? this.inkMuted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      destructive: destructive ?? this.destructive,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppCustomColors get colors =>
      Theme.of(this).extension<AppCustomColors>() ?? AppCustomColors.light;
}

class AppTheme {
  AppTheme._();

  static const List<String> proseFontFallbacks = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'SF Pro Text',
    'Roboto',
    'Segoe UI',
    'sans-serif',
  ];

  static const List<String> monoFontFallbacks = [
    'JetBrains Mono',
    'SF Mono',
    'Cascadia Code',
    'Consolas',
    'Fira Code',
    'monospace',
  ];

  static const double bodyFontSize = 15.5;
  static const double bodyLineHeight = 1.55;
  static const double maxContentWidth = 720.0;

  static ThemeData light() {
    const c = AppCustomColors.light;
    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: Brightness.light,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      fontFamilyFallback: proseFontFallbacks,
      colorScheme: ColorScheme.light(
        surface: c.background,
        primary: c.accent,
        onPrimary: c.background,
        onSurface: c.inkPrimary,
        outline: c.border,
        error: c.destructive,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: c.inkPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: c.inkPrimary, size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: c.inkPrimary,
        size: 20,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inkPrimary,
        contentTextStyle: TextStyle(color: c.background, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [c],
    );
  }

  static ThemeData dark() {
    const c = AppCustomColors.dark;
    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      fontFamilyFallback: proseFontFallbacks,
      colorScheme: ColorScheme.dark(
        surface: c.background,
        primary: c.accent,
        onPrimary: c.background,
        onSurface: c.inkPrimary,
        outline: c.border,
        error: c.destructive,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.inkPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: c.inkPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: c.inkPrimary, size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: c.inkPrimary,
        size: 20,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: TextStyle(color: c.inkPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: const [c],
    );
  }
}
