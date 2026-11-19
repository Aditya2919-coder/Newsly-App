import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_style.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.parentBgColor,
    );
    return ThemeData(
      fontFamily: AppTextStyle.fontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.screenBgColor,
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
      hoverColor: AppColors.transparent,
      focusColor: AppColors.transparent,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyle.veryLargeHeader,
        displayMedium: AppTextStyle.largeHeader,
        displaySmall: AppTextStyle.mediumHeader,
        headlineMedium: AppTextStyle.smallHeader,
        bodyLarge: AppTextStyle.largeNormalText,
        bodyMedium: AppTextStyle.mediumNormalText,
        bodySmall: AppTextStyle.smallNormalText,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.parentBgColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      fontFamily: AppTextStyle.fontFamily,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
      hoverColor: AppColors.transparent,
      focusColor: AppColors.transparent,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
        ),
      ),
    );
  }
}
