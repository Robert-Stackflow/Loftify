import 'package:flutter/material.dart';

import 'colors.dart';

class MyStyles {
  static const TextStyle text = TextStyle(
      fontSize: 14,
      color: MyColors.textColor,
      textBaseline: TextBaseline.alphabetic);
  static const TextStyle textDark = TextStyle(
      fontSize: 14,
      color: MyColors.textColorDark,
      textBaseline: TextBaseline.alphabetic);

  static const TextStyle labelSmallDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    letterSpacing: 0.1,
    color: MyColors.textGrayColorDark,
  );

  static const TextStyle labelSmall = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 12,
    letterSpacing: 0.1,
    color: MyColors.textGrayColor,
  );

  static const TextStyle captionDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textGrayColorDark,
  );

  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textGrayColor,
  );

  static const TextStyle titleDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 16,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 16,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );

  static const TextStyle titleLargeDark = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    letterSpacing: 0.18,
    color: MyColors.textColorDark,
  );

  static const TextStyle titleLarge = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 17,
    letterSpacing: 0.18,
    color: MyColors.textColor,
  );

  static const TextStyle bodySmallDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle bodySmall = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 13,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );

  static const TextStyle bodyMediumDark = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    letterSpacing: 0.1,
    color: MyColors.textColorDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    letterSpacing: 0.1,
    color: MyColors.textColor,
  );
}
