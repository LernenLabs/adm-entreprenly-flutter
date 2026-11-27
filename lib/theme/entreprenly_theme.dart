import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared with the Kotlin design system. Values are logical pixels.
abstract final class BrandMetrics {
  static const pagePadding = 14.0;
  static const cardPadding = 14.0;
  static const cardRadius = 14.0;
  static const fieldRadius = 12.0;
  static const buttonHeight = 52.0;
  static const buttonRadius = 28.0;
  static const toolbarHeight = 64.0;
}

/// Semantic colors without a Material ColorScheme slot.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.background,
    required this.highlight,
    required this.success,
    required this.successBackground,
    required this.warning,
    required this.warningBackground,
  });

  final Color background;
  final Color highlight;
  final Color success;
  final Color successBackground;
  final Color warning;
  final Color warningBackground;

  static BrandColors of(BuildContext context) =>
      Theme.of(context).extension<BrandColors>()!;

  static const light = BrandColors(
    background: Color(0xFFF6F4F4),
    highlight: Color(0xFFFFF3E3),
    success: Color(0xFF15803D),
    successBackground: Color(0xFFDCFCE7),
    warning: Color(0xFF713F12),
    warningBackground: Color(0xFFFEF3C7),
  );

  static const dark = BrandColors(
    background: Color(0xFF171513),
    highlight: Color(0xFF3A2B1B),
    success: Color(0xFF4ADE80),
    successBackground: Color(0xFF1F2A1F),
    warning: Color(0xFFFDE68A),
    warningBackground: Color(0xFF3A3012),
  );

  @override
  BrandColors copyWith({
    Color? background,
    Color? highlight,
    Color? success,
    Color? successBackground,
    Color? warning,
    Color? warningBackground,
  }) => BrandColors(
    background: background ?? this.background,
    highlight: highlight ?? this.highlight,
    success: success ?? this.success,
    successBackground: successBackground ?? this.successBackground,
    warning: warning ?? this.warning,
    warningBackground: warningBackground ?? this.warningBackground,
  );

  @override
  BrandColors lerp(covariant BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      background: Color.lerp(background, other.background, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBackground: Color.lerp(
        warningBackground,
        other.warningBackground,
        t,
      )!,
    );
  }
}

abstract final class EntreprenlyTheme {
  static const primary = Color(0xFFF38313);
  static const onPrimary = Color(0xFF1F1A16);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  // Explicit Material 3 scale: Flutter's defaults differ from Compose in tracking.
  static TextStyle _type(
    double size,
    double lineHeight,
    FontWeight weight, [
    double tracking = 0,
  ]) => TextStyle(
    fontFamily: 'RedditSans',
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking,
  );

  static final _typography = TextTheme(
    displayLarge: _type(57, 64, FontWeight.w400),
    displayMedium: _type(45, 52, FontWeight.w400),
    displaySmall: _type(36, 44, FontWeight.w400),
    headlineLarge: _type(32, 40, FontWeight.w400),
    headlineMedium: _type(28, 36, FontWeight.w400),
    headlineSmall: _type(24, 32, FontWeight.w400),
    titleLarge: _type(22, 28, FontWeight.w400),
    titleMedium: _type(16, 24, FontWeight.w500, .2),
    titleSmall: _type(14, 20, FontWeight.w500, .1),
    bodyLarge: _type(16, 24, FontWeight.w400, .5),
    bodyMedium: _type(14, 20, FontWeight.w400, .2),
    bodySmall: _type(12, 16, FontWeight.w400, .4),
    labelLarge: _type(14, 20, FontWeight.w500, .1),
    labelMedium: _type(12, 16, FontWeight.w500, .5),
    labelSmall: _type(11, 16, FontWeight.w500, .5),
  );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final extra = isDark ? BrandColors.dark : BrandColors.light;
    final surface = isDark ? const Color(0xFF25211E) : Colors.white;
    final text = isDark ? const Color(0xFFFFF7EE) : onPrimary;
    final muted = isDark ? const Color(0xFFD2C6BC) : const Color(0xFF6B6763);
    final border = isDark ? const Color(0xFF6A5F55) : const Color(0xFFE9E4DF);
    final error = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final errorBackground = isDark
        ? const Color(0xFF3A1B1B)
        : const Color(0xFFFEF2F2);
    // No seed/dynamic colors: preserve the exact brand in both themes.
    final colors = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: extra.highlight,
      onPrimaryContainer: text,
      secondary: muted,
      onSecondary: isDark ? extra.background : surface,
      secondaryContainer: extra.highlight,
      onSecondaryContainer: text,
      tertiary: primary,
      onTertiary: onPrimary,
      tertiaryContainer: extra.highlight,
      onTertiaryContainer: text,
      error: error,
      onError: isDark ? onPrimary : Colors.white,
      errorContainer: errorBackground,
      onErrorContainer: error,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border,
      surfaceDim: extra.background,
      surfaceBright: surface,
      surfaceContainerLowest: extra.background,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      surfaceTint: Colors.transparent,
    );
    final typography = _typography.apply(bodyColor: text, displayColor: text);
    final buttonText = typography.labelLarge!.copyWith(
      fontWeight: FontWeight.w700,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BrandMetrics.buttonRadius),
    );
    OutlineInputBorder fieldBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(BrandMetrics.fieldRadius),
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'RedditSans',
      textTheme: typography,
      extensions: [extra],
      scaffoldBackgroundColor: extra.background,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: BrandMetrics.toolbarHeight,
        centerTitle: false,
        titleTextStyle: typography.titleLarge!.copyWith(
          color: onPrimary,
          fontWeight: FontWeight.w800,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: primary,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandMetrics.cardRadius),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: border,
          disabledForegroundColor: muted,
          minimumSize: const Size(0, BrandMetrics.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: buttonText,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: text,
          disabledForegroundColor: muted,
          minimumSize: const Size(0, BrandMetrics.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: buttonText,
          shape: buttonShape,
          side: BorderSide(color: border),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.error) ? errorBackground : surface,
        ),
        labelStyle: buttonText,
        hintStyle: typography.bodyLarge!.copyWith(color: muted),
        errorStyle: typography.bodySmall!.copyWith(color: error),
        prefixIconColor: muted,
        border: fieldBorder(border),
        enabledBorder: fieldBorder(border),
        disabledBorder: fieldBorder(border),
        focusedBorder: fieldBorder(primary),
        errorBorder: fieldBorder(error),
        focusedErrorBorder: fieldBorder(error),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: typography.titleLarge!.copyWith(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandMetrics.cardRadius),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
