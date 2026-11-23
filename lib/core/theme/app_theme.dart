import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const bangla = 'HindSiliguri';
  static const arabic = 'Amiri';
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: isDark ? AppColors.emerald500 : AppColors.emerald700,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.emerald800 : AppColors.emerald100,
      onPrimaryContainer: isDark ? AppColors.emerald50 : AppColors.emerald900,
      secondary: AppColors.gold,
      onSecondary: AppColors.emerald950,
      secondaryContainer: isDark ? const Color(0xFF3A3020) : AppColors.cream200,
      onSecondaryContainer: isDark ? AppColors.goldLight : AppColors.goldDeep,
      tertiary: AppColors.goldDeep,
      onTertiary: Colors.white,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: isDark ? AppColors.nightSurface : AppColors.cream,
      onSurface: isDark ? const Color(0xFFE9E4D6) : AppColors.ink,
      onSurfaceVariant: isDark ? const Color(0xFFA9B5AE) : AppColors.inkSoft,
      surfaceContainerLowest: isDark ? AppColors.night : Colors.white,
      surfaceContainerLow: isDark ? AppColors.nightCard : Colors.white,
      surfaceContainer: isDark ? AppColors.nightCard : AppColors.cream200,
      surfaceContainerHigh: isDark ? const Color(0xFF1B342B) : AppColors.cream300,
      outline: isDark ? const Color(0xFF2E4A3F) : AppColors.cream300,
      outlineVariant: isDark ? const Color(0xFF223A31) : const Color(0xFFEFE6D2),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.bangla,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.bangla,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
        indicatorColor: isDark ? AppColors.emerald800 : AppColors.emerald100,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: AppFonts.bangla,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: AppColors.gold,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
            fontFamily: AppFonts.bangla, fontWeight: FontWeight.w700, fontSize: 15),
        unselectedLabelStyle: const TextStyle(
            fontFamily: AppFonts.bangla, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: AppColors.gold,
        inactiveTrackColor: scheme.outline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.gold : null),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : null),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}
