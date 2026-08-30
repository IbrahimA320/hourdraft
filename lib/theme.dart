import 'package:flutter/material.dart';

/// AppColors used to be a set of `static const Color` values. To support
/// dark mode without rewriting every screen, each color is now a `static
/// Color get` that switches on [AppColors.isDark]. [isDark] is set once per
/// frame in main.dart right before the widget tree is built, based on the
/// user's theme choice (system / light / dark).
///
/// IMPORTANT: because these are no longer compile-time constants, any place
/// in the code that wrote `const BorderSide(color: AppColors.border)` or
/// `const TextStyle(color: AppColors.text)` (etc.) will fail to compile with
/// "not a constant expression". The fix is mechanical: delete the `const`
/// keyword right before that widget/value. The Dart analyzer will point at
/// every spot that needs it.
class AppColors {
  static bool isDark = false;

  static Color get bg => isDark ? const Color(0xFF16140F) : const Color(0xFFF5F2ED);
  static Color get surface => isDark ? const Color(0xFF201D17) : const Color(0xFFFFFFFF);
  static Color get surface2 => isDark ? const Color(0xFF2A261E) : const Color(0xFFF0EDE8);
  static Color get border => isDark ? const Color(0xFF3A352A) : const Color(0xFFE0DDD8);
  static Color get text => isDark ? const Color(0xFFF2EFE8) : const Color(0xFF1A1815);
  static Color get textMuted => isDark ? const Color(0xFFA39C8D) : const Color(0xFF77736D);

  static Color get accent => isDark ? const Color(0xFF6FBF42) : const Color(0xFF2D5016);
  static Color get accentLight => isDark ? const Color(0xFF223318) : const Color(0xFFEAF0E3);

  static Color get danger => isDark ? const Color(0xFFE07A7A) : const Color(0xFF8B1F1F);
  static Color get dangerLight => isDark ? const Color(0xFF3A2222) : const Color(0xFFF5E8E8);

  static Color get indoor => isDark ? const Color(0xFF5B9BD9) : const Color(0xFF1A4A7A);
  static Color get indoorLight => isDark ? const Color(0xFF1E2B3A) : const Color(0xFFE3EBF5);

  static Color get outdoor => isDark ? const Color(0xFF6FBF42) : const Color(0xFF2D5016);
  static Color get outdoorLight => isDark ? const Color(0xFF223318) : const Color(0xFFEAF0E3);

  static Color get group => isDark ? const Color(0xFFB07CE0) : const Color(0xFF6B21A8);
  static Color get groupLight => isDark ? const Color(0xFF2E2338) : const Color(0xFFF3E8FF);

  static Color get approved => isDark ? const Color(0xFF6ED28F) : const Color(0xFF166534);
  static Color get approvedLight => isDark ? const Color(0xFF1D3324) : const Color(0xFFDCFCE7);

  static Color get pending => isDark ? const Color(0xFFE0B15A) : const Color(0xFF92400E);
  static Color get pendingLight => isDark ? const Color(0xFF3A2E14) : const Color(0xFFFEF3C7);

  /// Used to shade a blocked / unavailable date on the calendar.
  static Color get blocked => isDark ? const Color(0xFF3A2A2A) : const Color(0xFFF0E3E3);
  static Color get blockedText => isDark ? const Color(0xFFC98A8A) : const Color(0xFF9A4B4B);
}

class AppTheme {
  /// Call this once per build (see main.dart) before rendering the tree, so
  /// every AppColors.* getter used during that build resolves consistently.
  static void applyBrightness(bool dark) {
    AppColors.isDark = dark;
  }

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      primary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      dividerTheme: DividerThemeData(color: AppColors.border, space: 1),
    );
  }
}