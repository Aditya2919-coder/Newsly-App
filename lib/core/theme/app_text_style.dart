import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTextStyle {
  const AppTextStyle._();

  static const String fontFamily = 'Figtree';

  static const TextStyle veryLargeHeader = TextStyle(
    color: AppColors.black,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  static const TextStyle largeHeader = TextStyle(
    color: AppColors.black,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  static const TextStyle mediumHeader = TextStyle(
    color: AppColors.black,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static const TextStyle smallHeader = TextStyle(
    color: AppColors.black,
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
  );

  static const TextStyle largeNormalText = TextStyle(
    color: AppColors.black,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle mediumNormalText = TextStyle(
    color: AppColors.black,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle smallNormalText = TextStyle(
    color: AppColors.black,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
}
