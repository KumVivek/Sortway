import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bgTop = Color(0xFF1B2452);
  static const bgBottom = Color(0xFF0E1330);
  static const surface = Color(0xFF263168);
  static const surfaceHigh = Color(0xFF33407F);
  static const track = Color(0xFF3A4686);
  static const trackActive = Color(0xFFFFE08A);
  static const accent = Color(0xFFFFC83D);
  static const onAccent = Color(0xFF2A1F00);
  static const good = Color(0xFF35D08A);
  static const bad = Color(0xFFFF6B6B);
  static const text = Color(0xFFFFFFFF);
  static const textDim = Color(0xFFB4BEEA);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.bad,
  );
  const radius = BorderRadius.all(Radius.circular(18));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgBottom,
    textTheme: const TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.35),
      bodyMedium: TextStyle(height: 1.35),
      labelLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.surfaceHigh, width: 2),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.textDim,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? AppColors.onAccent
                : AppColors.textDim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.bgBottom,
      ),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textDim),
    dividerTheme: const DividerThemeData(color: AppColors.surfaceHigh),
  );
}

/// Full-screen gradient used behind every screen.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.bgTop, AppColors.bgBottom],
      ),
    ),
    child: child,
  );
}
