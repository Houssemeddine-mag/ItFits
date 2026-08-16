import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryLight = Color(0xFF8B6B5A);
  static const Color primaryDark = Color(0xFFD4B8A3);
  static const Color secondaryLight = Color(0xFF6B8E8E);
  static const Color secondaryDark = Color(0xFF98C2C2);
  static const Color accentLight = Color(0xFFD4A574);
  static const Color accentDark = Color(0xFFE8C596);
  static const Color surfaceLight = Color(0xFFFAF8F5);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF1E1E1E);
  static const Color onSurfaceLight = Color(0xFF1E2A3A);
  static const Color onSurfaceDark = Color(0xFFF0EDE8);
  static const Color onSurfaceVariantLight = Color(0xFF4A5A6A);
  static const Color onSurfaceVariantDark = Color(0xFFB8C5D1);
  static const Color outlineLight = Color(0xFFE0DDD8);
  static const Color outlineDark = Color(0xFF4A5A6A);
  static const Color outlineVariantLight = Color(0xFFD0CEC8);
  static const Color outlineVariantDark = Color(0xFF3E506B);
  static const Color errorLight = Color(0xFFC62828);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color successLight = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF7FC48C);
  static const Color warningLight = Color(0xFFF57F17);
  static const Color warningDark = Color(0xFFFFD700);
  static const Color neutral100 = Color(0xFFF5F0EB);
  static const Color neutral200 = Color(0xFFE8E0D8);
  static const Color neutral300 = Color(0xFFD4C8BB);
  static const Color neutral400 = Color(0xFFB8A898);
  static const Color neutral500 = Color(0xFF9C8A78);
  static const Color neutral600 = Color(0xFF7D6D5D);
  static const Color neutral700 = Color(0xFF5E5042);
  static const Color neutral800 = Color(0xFF3F362D);
  static const Color neutral900 = Color(0xFF26221E);
  static const Color warmWhite = Color(0xFFFAF8F5);
  static const Color warmBlack = Color(0xFF1A1614);

  static const Color primaryContainerLight = Color(0x1A8B6B5A);
  static const Color secondaryContainerLight = Color(0x1A6B8E8E);
  static const Color tertiaryContainerLight = Color(0x1AD4A574);
  static const Color shadowLight = Color(0x1A1A1614);
  static const Color scrimLight = Color(0x1A1A1614);
  static const Color errorContainerLight = Color(0xFFFFEBEE);
  static const Color inverseSurfaceLight = Color(0xFF1E1E1E);
  static const Color inversePrimaryLight = Color(0xFFD4A574);

  static const Color primaryContainerDark = Color(0x1AD4A574);
  static const Color secondaryContainerDark = Color(0x1A6B8E8E);
  static const Color tertiaryContainerDark = Color(0x1A6B8E8E);
  static const Color shadowDark = Color(0x4D000000);
  static const Color scrimDark = Color(0x4D000000);
  static const Color errorContainerDark = Color(0xFFB71C1C);
  static const Color inverseSurfaceDark = Color(0xFFFFFFFF);
  static const Color inversePrimaryDark = Color(0xFF8B6B5A);

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: onPrimaryLight,
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: primaryDark,
    secondary: secondaryLight,
    onSecondary: onPrimaryLight,
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: secondaryDark,
    tertiary: accentLight,
    onTertiary: onPrimaryLight,
    tertiaryContainer: tertiaryContainerLight,
    onTertiaryContainer: accentDark,
    error: errorLight,
    onError: onPrimaryLight,
    errorContainer: errorContainerLight,
    onErrorContainer: errorDark,
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    surfaceContainerHighest: neutral100,
    surfaceContainerHigh: neutral200,
    surfaceContainer: neutral300,
    surfaceContainerLow: neutral400,
    surfaceContainerLowest: backgroundLight,
    outline: outlineLight,
    outlineVariant: outlineVariantLight,
    shadow: shadowLight,
    scrim: scrimLight,
    inverseSurface: inverseSurfaceLight,
    onInverseSurface: backgroundLight,
    inversePrimary: inversePrimaryLight,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accentLight,
    onPrimary: onPrimaryDark,
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: accentLight,
    secondary: secondaryLight,
    onSecondary: onPrimaryDark,
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: secondaryLight,
    tertiary: accentDark,
    onTertiary: onPrimaryDark,
    tertiaryContainer: tertiaryContainerDark,
    onTertiaryContainer: accentLight,
    error: errorDark,
    onError: onPrimaryDark,
    errorContainer: errorContainerDark,
    onErrorContainer: Color(0xFFFFEBEE),
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    surfaceContainerHighest: Color(0xFF2D3A4A),
    surfaceContainerHigh: Color(0xFF2D3A4A),
    surfaceContainer: Color(0xFF2D3A4A),
    surfaceContainerLow: Color(0xFF2D3A4A),
    surfaceContainerLowest: backgroundDark,
    outline: outlineDark,
    outlineVariant: outlineVariantDark,
    shadow: shadowDark,
    scrim: scrimDark,
    inverseSurface: inverseSurfaceDark,
    onInverseSurface: warmBlack,
    inversePrimary: inversePrimaryDark,
  );

  static ThemeData get light => _buildTheme(lightColorScheme, Brightness.light);
  static ThemeData get dark => _buildTheme(darkColorScheme, Brightness.dark);

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    final displayFont = GoogleFonts.dmSerifDisplayTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme.copyWith(
        displayLarge: displayFont.displayLarge,
        displayMedium: displayFont.displayMedium,
        displaySmall: displayFont.displaySmall,
        headlineLarge: displayFont.headlineLarge,
        headlineMedium: displayFont.headlineMedium,
        headlineSmall: displayFont.headlineSmall,
        titleLarge: displayFont.titleLarge,
        titleMedium: displayFont.titleMedium,
        titleSmall: displayFont.titleSmall,
      ),
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
        shadowColor: colorScheme.shadow,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHigh,
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        brightness: brightness,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle();
          }
          return textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle();
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actionTextColor: colorScheme.primary,
      ),
      extensions: <ThemeExtension<dynamic>>[
        if (brightness == Brightness.light) AppColorsLight() else AppColorsDark(),
      ],
    );
  }
}

class AppColorsLight extends ThemeExtension<AppColorsLight> {
  final Color warmWhite = AppTheme.warmWhite;
  final Color warmBlack = AppTheme.warmBlack;
  final Color neutral100 = AppTheme.neutral100;
  final Color neutral200 = AppTheme.neutral200;
  final Color neutral300 = AppTheme.neutral300;
  final Color neutral400 = AppTheme.neutral400;
  final Color neutral500 = AppTheme.neutral500;
  final Color neutral600 = AppTheme.neutral600;
  final Color neutral700 = AppTheme.neutral700;
  final Color neutral800 = AppTheme.neutral800;
  final Color neutral900 = AppTheme.neutral900;

  @override
  AppColorsLight copyWith() => AppColorsLight();

  @override
  AppColorsLight lerp(ThemeExtension<AppColorsLight>? other, double t) => this;
}

class AppColorsDark extends ThemeExtension<AppColorsDark> {
  final Color warmWhite = AppTheme.warmWhite;
  final Color warmBlack = AppTheme.warmBlack;
  final Color neutral100 = AppTheme.neutral100;
  final Color neutral200 = AppTheme.neutral200;
  final Color neutral300 = AppTheme.neutral300;
  final Color neutral400 = AppTheme.neutral400;
  final Color neutral500 = AppTheme.neutral500;
  final Color neutral600 = AppTheme.neutral600;
  final Color neutral700 = AppTheme.neutral700;
  final Color neutral800 = AppTheme.neutral800;
  final Color neutral900 = AppTheme.neutral900;

  @override
  AppColorsDark copyWith() => AppColorsDark();

  @override
  AppColorsDark lerp(ThemeExtension<AppColorsDark>? other, double t) => this;
}

final appThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.light;
});