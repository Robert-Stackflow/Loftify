import 'package:flutter/material.dart';

import '../Utils/app_provider.dart';
import '../Utils/responsive_util.dart';
import '../Utils/utils.dart';
import 'colors.dart';
import 'styles.dart';

class MyTheme {
  MyTheme._();

  static bool get isDarkMode =>
      Theme.of(rootContext).brightness == Brightness.dark;

  static ThemeData getTheme({required bool isDarkMode}) {
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: isDarkMode
          ? MyColors.defaultPrimaryColorDark
          : MyColors.defaultPrimaryColor,
      hintColor: isDarkMode
          ? MyColors.defaultPrimaryColorDark
          : MyColors.defaultPrimaryColor,
      indicatorColor: isDarkMode
          ? MyColors.defaultPrimaryColorDark
          : MyColors.defaultPrimaryColor,
      scaffoldBackgroundColor:
          isDarkMode ? MyColors.backgroundDark : MyColors.background,
      canvasColor: isDarkMode
          ? MyColors.materialBackgroundDark
          : MyColors.materialBackground,
      dividerColor:
          isDarkMode ? MyColors.dividerColorDark : MyColors.dividerColor,
      shadowColor: isDarkMode ? MyColors.shadowColorDark : MyColors.shadowColor,
      splashColor: isDarkMode ? MyColors.splashColorDark : MyColors.splashColor,
      highlightColor:
          isDarkMode ? MyColors.highlightColorDark : MyColors.highlightColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? MyColors.materialBackgroundDark
                : MyColors.materialBackground;
          } else {
            return isDarkMode
                ? MyColors.textGrayColorDark
                : MyColors.textGrayColor;
          }
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? MyColors.defaultPrimaryColorDark
                : MyColors.defaultPrimaryColor;
          } else {
            return null;
          }
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDarkMode
                ? MyColors.defaultPrimaryColorDark
                : MyColors.defaultPrimaryColor;
          } else {
            return isDarkMode
                ? MyColors.materialBackgroundDark
                : MyColors.materialBackground;
          }
        }),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: isDarkMode ? MyColors.iconColorDark : MyColors.iconColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: MyColors.defaultPrimaryColor.withAlpha(70),
        selectionHandleColor: MyColors.defaultPrimaryColor,
      ),
      textTheme: TextTheme(
        labelSmall: isDarkMode ? MyStyles.labelSmallDark : MyStyles.labelSmall,
        titleSmall: isDarkMode ? MyStyles.captionDark : MyStyles.caption,
        titleMedium: isDarkMode ? MyStyles.titleDark : MyStyles.title,
        bodySmall: isDarkMode ? MyStyles.bodySmallDark : MyStyles.bodySmall,
        bodyMedium: isDarkMode ? MyStyles.bodyMediumDark : MyStyles.bodyMedium,
        titleLarge: isDarkMode ? MyStyles.titleLargeDark : MyStyles.titleLarge,
        bodyLarge: isDarkMode ? MyStyles.textDark : MyStyles.text,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0.0,
        backgroundColor: isDarkMode
            ? MyColors.appBarBackgroundDark
            : MyColors.appBarBackground,
      ),
    );
  }

  static const TextTheme textTheme = TextTheme(
    headlineMedium: display1,
    headlineSmall: headline,
    titleLarge: title,
    titleSmall: subtitle,
    bodyMedium: body2,
    bodyLarge: body1,
    bodySmall: caption,
  );
  static const TextStyle display1 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 36,
    letterSpacing: 0.4,
    height: 0.9,
  );

  static const TextStyle headline = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 0.27,
  );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: 0.18,
  );

  static const TextStyle itemTitle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: 0.1,
  );

  static const TextStyle itemTitleLittle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    letterSpacing: 0.1,
  );

  static const TextStyle itemTip = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    letterSpacing: 0.1,
  );

  static const TextStyle itemTipLittle = TextStyle(
    fontWeight: FontWeight.normal,
    fontSize: 11,
    letterSpacing: 0.1,
  );

  static const TextStyle subtitle = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: -0.04,
  );

  static const TextStyle body2 = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    letterSpacing: 0.2,
  );

  static const TextStyle body1 = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    letterSpacing: -0.05,
  );

  static const TextStyle caption = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    letterSpacing: 0.2,
  );

  static List<BoxShadow> get defaultBoxShadow {
    return [
      BoxShadow(
        color: Theme.of(rootContext).shadowColor,
        offset: const Offset(0, 4),
        blurRadius: 10,
        spreadRadius: 1,
      ).scale(2),
    ];
  }

  static BoxDecoration get defaultDecoration {
    return BoxDecoration(
      color: Theme.of(rootContext).canvasColor,
      border: Border.all(color: Theme.of(rootContext).dividerColor, width: 1),
      boxShadow: defaultBoxShadow,
      borderRadius: BorderRadius.circular(10),
    );
  }

  static BoxDecoration getDefaultDecoration(
      [double radius = 10, double borderWidth = 1]) {
    return BoxDecoration(
      color: Theme.of(rootContext).canvasColor,
      border: Border.all(
          color: Theme.of(rootContext).dividerColor, width: borderWidth),
      boxShadow: defaultBoxShadow,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static Border get bottomBorder {
    return Border(bottom: borderSide);
  }

  static Border get topBorder {
    return Border(top: borderSide);
  }

  static Border get border {
    return Border.all(color: Theme.of(rootContext).dividerColor, width: 0.5);
  }

  static BorderSide get borderSide {
    return BorderSide(color: Theme.of(rootContext).dividerColor, width: 0.5);
  }

  static getBackground(BuildContext context) {
    return Utils.currentBrightness(context) == Brightness.light
        ? canvasColor
        : scaffoldBackgroundColor;
  }

  static getCardBackground(BuildContext context) {
    return Utils.currentBrightness(context) == Brightness.light
        ? scaffoldBackgroundColor
        : canvasColor;
  }

  static Color get background {
    return Utils.currentBrightness(rootContext) == Brightness.light
        ? scaffoldBackgroundColor
        : scaffoldBackgroundColor;
  }

  static Color get itemBackground {
    if (ResponsiveUtil.isLandscape()) {
      return canvasColor;
    }
    return Utils.currentBrightness(rootContext) == Brightness.light
        ? canvasColor
        : scaffoldBackgroundColor;
  }

  static Color get primaryColor => Theme.of(rootContext).primaryColor;

  static Color get canvasColor => Theme.of(rootContext).canvasColor;

  static Color get scaffoldBackgroundColor =>
      Theme.of(rootContext).scaffoldBackgroundColor;
}
