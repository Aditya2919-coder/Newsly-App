import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/routing/app_nav_keys.dart';
import '../../../core/theme/app_text_style.dart';

/// Lightweight toast service using Flutter's SnackBar.
class ToastServices {
  ToastServices._();

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData icon = Icons.info_outline,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = AppNavKeys.appNavKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 10.0,
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.smallHeader.copyWith(color: textColor),
                  ),
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: AppTextStyle.smallNormalText.copyWith(
                        color: textColor.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        duration: duration,
      ),
    );
  }

  static void success(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.successGreen,
      textColor: AppColors.white,
      icon: Icons.check_circle_outline,
    );
  }

  static void error(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.dangerRed,
      textColor: AppColors.white,
      icon: Icons.error_outline,
    );
  }

  static void warning(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.warningAmberLight,
      textColor: AppColors.labelDark,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void message(String title, String message) {
    _show(
      title: title,
      message: message,
      backgroundColor: AppColors.messageToastBgColor,
      textColor: AppColors.labelDark,
      icon: Icons.message_outlined,
    );
  }
}
