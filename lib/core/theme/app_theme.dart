import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds the premium light & dark Material 3 themes.
///
/// Fonts are bundled (see pubspec `fonts:`) so the app renders correctly
/// offline — no runtime font download.
class AppTheme {
  AppTheme._();

  static const String _body = 'Inter';
  static const String _display = 'SpaceGrotesk';

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final textDim = isDark ? AppColors.darkTextDim : AppColors.lightTextDim;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      error: const Color(0xFFFF5470),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: card,
      outline: border,
    );

    final baseText = (isDark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(fontFamily: _body);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: _body,
      textTheme: baseText.apply(bodyColor: text, displayColor: text).copyWith(
            displayLarge: TextStyle(
              fontFamily: _display,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: -1,
            ),
            displayMedium: TextStyle(
              fontFamily: _display,
              fontWeight: FontWeight.w700,
              color: text,
              letterSpacing: -0.5,
            ),
            displaySmall: TextStyle(
              fontFamily: _display,
              fontWeight: FontWeight.w700,
              color: text,
            ),
            headlineMedium: TextStyle(
              fontFamily: _display,
              fontWeight: FontWeight.w700,
              color: text,
            ),
            titleLarge: TextStyle(
              fontFamily: _display,
              fontWeight: FontWeight.w700,
              color: text,
            ),
            titleMedium: TextStyle(
              fontFamily: _body,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: text,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: _display,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      iconTheme: IconThemeData(color: textDim),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        labelStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
        side: BorderSide(color: border),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      extensions: [
        AppSemanticColors(
          textDim: textDim,
          border: border,
          card: card,
          bg2: isDark ? AppColors.darkBg2 : AppColors.lightBg2,
        ),
      ],
    );
  }
}

/// Extra semantic colors not covered by [ColorScheme].
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.textDim,
    required this.border,
    required this.card,
    required this.bg2,
  });

  final Color textDim;
  final Color border;
  final Color card;
  final Color bg2;

  @override
  AppSemanticColors copyWith({
    Color? textDim,
    Color? border,
    Color? card,
    Color? bg2,
  }) =>
      AppSemanticColors(
        textDim: textDim ?? this.textDim,
        border: border ?? this.border,
        card: card ?? this.card,
        bg2: bg2 ?? this.bg2,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      textDim: Color.lerp(textDim, other.textDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
}
