import 'package:flutter/material.dart';

/// 블랙 & 옐로우 브랜드 팔레트
const kBlack = Color(0xFF181818);
const kBlackSoft = Color(0xFF2B2B2B);
const kYellow = Color(0xFFFFD21A);
const kYellowDark = Color(0xFFE0B400);
const kBg = Color(0xFFF4F4F1);
const kBorder = Color(0xFFE3E3DD);
const kInk = Color(0xFF1A1A1A);
const kMuted = Color(0xFF7A7A72);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kYellow,
    brightness: Brightness.light,
  ).copyWith(
    primary: kBlack,
    onPrimary: kYellow,
    secondary: kYellow,
    onSecondary: kBlack,
    surface: Colors.white,
    onSurface: kInk,
  );

  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    splashColor: kYellow.withValues(alpha: 0.18),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBlack,
      foregroundColor: kYellow,
      elevation: 0,
      titleTextStyle: TextStyle(
          color: kYellow, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.2),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorder),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFAFAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(kBorder),
      enabledBorder: border(kBorder),
      focusedBorder: border(kBlack, 1.8),
      hintStyle: const TextStyle(color: Color(0xFFB2B2AA)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBlack,
        foregroundColor: kYellow,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kBlack),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: kBlack,
      unselectedLabelColor: kMuted,
      indicatorColor: kYellowDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1, space: 18),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: kBlack,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme().apply(bodyColor: kInk, displayColor: kInk),
  );
}

/// 노란 강조 CTA (완료 등 최종 액션)
final ButtonStyle kYellowCta = FilledButton.styleFrom(
  backgroundColor: kYellow,
  foregroundColor: kBlack,
  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
);
