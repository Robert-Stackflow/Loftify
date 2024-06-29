import 'package:flutter/material.dart';

import 'colors.dart';
import 'dimens.dart';

class MyStyles {
  static const TextStyle textSize12 = TextStyle(
    fontSize: MyDimens.font_sp12,
  );
  static const TextStyle textSize16 = TextStyle(
    fontSize: MyDimens.font_sp16,
  );
  static const TextStyle textBold14 =
      TextStyle(fontSize: MyDimens.font_sp14, fontWeight: FontWeight.bold);
  static const TextStyle textBold16 =
      TextStyle(fontSize: MyDimens.font_sp16, fontWeight: FontWeight.bold);
  static const TextStyle textBold18 =
      TextStyle(fontSize: MyDimens.font_sp18, fontWeight: FontWeight.bold);
  static const TextStyle textBold24 =
      TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold);
  static const TextStyle textBold26 =
      TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold);

  static const TextStyle textGray14 = TextStyle(
    fontSize: MyDimens.font_sp14,
    color: MyColors.textGrayColor,
  );
  static const TextStyle textDarkGray14 = TextStyle(
    fontSize: MyDimens.font_sp14,
    color: MyColors.textGrayColorDark,
  );

  static const TextStyle textWhite14 = TextStyle(
    fontSize: MyDimens.font_sp14,
    color: Colors.white,
  );

  static const TextStyle text = TextStyle(
      fontSize: MyDimens.font_sp14,
      color: MyColors.textColor,
      textBaseline: TextBaseline.alphabetic);
  static const TextStyle textDark = TextStyle(
      fontSize: MyDimens.font_sp14,
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
