import 'package:flutter/material.dart';
import 'package:loftify/Resources/colors.dart';

import 'fonts.dart';

class ThemeColorData {
  bool isDarkMode;

  String name;

  String? description;

  Color primaryColor;

  Color background;

  Color cardBackground;

  Color appBarBackgroundColor;

  Color appBarSurfaceTintColor;

  Color appBarShadowColor;

  double appBarElevation;

  double appBarScrollUnderElevation;

  Color splashColor;

  Color highlightColor;

  Color iconColor;

  Color shadowColor;

  Color canvasBackground;

  Color textColor;

  Color textGrayColor;

  Color textDisabledColor;

  Color buttonTextColor;

  Color buttonDisabledColor;

  Color dividerColor;

  Color tagBackground;

  Color tagColor;

  ThemeColorData({
    this.isDarkMode = false,
    required this.name,
    this.description,
    required this.cardBackground,
    required this.primaryColor,
    required this.background,
    required this.appBarBackgroundColor,
    required this.appBarSurfaceTintColor,
    required this.appBarShadowColor,
    this.appBarElevation = 0.0,
    this.appBarScrollUnderElevation = 1.0,
    required this.splashColor,
    required this.highlightColor,
    required this.iconColor,
    required this.shadowColor,
    required this.canvasBackground,
    required this.textColor,
    required this.textGrayColor,
    required this.textDisabledColor,
    required this.buttonTextColor,
    required this.buttonDisabledColor,
    required this.dividerColor,
    required this.tagBackground,
    required this.tagColor,
  });

  static List<ThemeColorData> defaultLightThemes = [
    ThemeColorData(
      name: "极简白",
      background: const Color(0xFFF7F8F9),
      canvasBackground: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFF14C2BB),
      iconColor: const Color(0xFF333333),
      splashColor: const Color(0x44c8c8c8),
      highlightColor: const Color(0x44bcbcbc),
      shadowColor: Colors.grey.shade200,
      appBarShadowColor: const Color(0xFFF6F6F6),
      appBarBackgroundColor: const Color(0xFFF7F8F9),
      appBarSurfaceTintColor: const Color(0xFFF7F8F9),
      textColor: const Color(0xFF333333),
      textGrayColor: const Color(0xFF999999),
      textDisabledColor: const Color(0xFFD4E2FA),
      buttonTextColor: const Color(0xFFF2F2F2),
      buttonDisabledColor: const Color(0xFF96BBFA),
      dividerColor: const Color(0xFFF5F5F5),
      tagBackground: const Color(0xFFF5F5F5),
      tagColor: const Color(0xFFBDBDBD),
      cardBackground: const Color(0xFFF5F5F5),
    ),
    ThemeColorData(
      name: "清新绿",
      background: const Color(0xFFE8F5E9), // 浅绿色背景
      canvasBackground: const Color(0xFFECF7EF), // 白色画布背景
      primaryColor: const Color(0xFF66BB6A), // 亮绿色主色
      iconColor: const Color(0xFF333333), // 深灰色图标
      splashColor: const Color(0x44c8c8c8), // 灰色飞溅色
      highlightColor: const Color(0x44bcbcbc), // 灰色高亮色
      shadowColor: Colors.grey.shade200, // 浅灰色阴影
      appBarShadowColor: const Color(0xFFF6F6F6), // 浅灰色AppBar阴影
      appBarBackgroundColor: const Color(0xFFE8F5E9), // 浅绿色AppBar背景
      appBarSurfaceTintColor: const Color(0xFFE8F5E9), // 浅绿色AppBar表面色调
      textColor: const Color(0xFF333333), // 深灰色文字
      textGrayColor: const Color(0xFF999999), // 灰色文字
      textDisabledColor: const Color(0xFFD4E2FA), // 浅蓝色禁用文字
      buttonTextColor: const Color(0xFFF2F2F2), // 浅灰色按钮文字
      buttonDisabledColor: const Color(0xFF96BBFA), // 浅蓝色禁用按钮
      dividerColor: const Color(0xFFF5F5F5), // 浅灰色分割线
      tagBackground: const Color(0xFFF5F5F5), // 浅灰色标签背景
      tagColor: const Color(0xFFBDBDBD), // 灰色标签文字
      cardBackground: const Color(0xFFF5F5F5), // 浅灰色卡片背景
    ),
  ];

  static List<ThemeColorData> defaultDarkThemes = [
    ThemeColorData(
      name: "极简黑",
      background: const Color(0xFF151515),
      canvasBackground: const Color(0xFF232326),
      primaryColor: const Color(0xFF14C2BB),
      iconColor: const Color(0xFFCACACA),
      splashColor: const Color(0x12cccccc),
      highlightColor: const Color(0x12cfcfcf),
      shadowColor: Colors.black.withAlpha(84),
      appBarShadowColor: const Color(0xFF1F1F1F),
      appBarBackgroundColor: const Color(0xFF232326),
      appBarSurfaceTintColor: const Color(0xFF232326),
      textColor: const Color(0xFFCCCCCC),
      textGrayColor: const Color(0xFF888888),
      textDisabledColor: const Color(0xFFCEDBF2),
      buttonTextColor: const Color(0xFFF2F2F2),
      buttonDisabledColor: const Color(0xFF83A5E0),
      dividerColor: const Color(0xFF303030),
      tagBackground: const Color(0xFF333333),
      tagColor: const Color(0xFF888888),
      cardBackground: const Color(0xFF333333),
    ),
    ThemeColorData(
      name: "蓝铁",
      background: const Color(0xFF1D2733),
      canvasBackground: const Color(0xFF242E39),
      cardBackground: const Color(0xFF2E3A45),
      primaryColor: const Color(0xFF14C2BB),
      iconColor: const Color(0xFFB8B8B8),
      splashColor: const Color(0x0Acccccc),
      highlightColor: const Color(0x0Acfcfcf),
      shadowColor: const Color(0xFF1B2530),
      appBarShadowColor: const Color(0xFF1B2530),
      appBarBackgroundColor: const Color(0xFF252E3A),
      appBarSurfaceTintColor: const Color(0xFF252E3A),
      textColor: const Color(0xFFB8B8B8),
      textGrayColor: const Color(0xFF6B7783),
      textDisabledColor: const Color(0xFFCEDBF2),
      buttonTextColor: const Color(0xFFF2F2F2),
      buttonDisabledColor: const Color(0xFF83A5E0),
      dividerColor: const Color(0xFF2D3743),
      tagBackground: const Color(0xFF424242),
      tagColor: const Color(0xFF757575),
    ),
  ];

  ThemeData toThemeData() {
    TextStyle labelSmall = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 11,
      letterSpacing: 0.1,
      color: tagColor,
    );

    TextStyle labelMedium = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 13,
      letterSpacing: 0.1,
      color: tagColor,
    );

    TextStyle labelLarge = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 15,
      letterSpacing: 0.1,
      color: tagColor,
    );

    TextStyle titleSmall = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 13,
      letterSpacing: 0.1,
      height: 1.2,
      color: textColor,
    );

    TextStyle titleMedium = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 16,
      letterSpacing: 0.1,
      color: textColor,
    );

    TextStyle titleLarge = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 17,
      letterSpacing: 0.18,
      color: textColor,
    );

    TextStyle bodySmall = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 12,
      letterSpacing: 0.1,
      color: textGrayColor,
    );

    TextStyle bodyMedium = TextStyle(
      fontWeight: FontWeight.normal,
      fontSize: 14,
      letterSpacing: 0.1,
      color: textColor,
    );

    TextStyle bodyLarge = TextStyle(
      fontSize: 16,
      color: textColor,
    );

    return ThemeData(
      fontFamily: FontEnum.getCurrentFont().fontFamily,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      hintColor: primaryColor,
      indicatorColor: primaryColor,
      scaffoldBackgroundColor: background,
      canvasColor: canvasBackground,
      dividerColor: dividerColor,
      shadowColor: shadowColor,
      splashColor: splashColor,
      highlightColor: highlightColor,
      cardColor: cardBackground,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return canvasBackground;
          } else {
            return textGrayColor.withAlpha(200);
          }
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return textGrayColor.withAlpha(40);
          }
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return canvasBackground;
          }
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          } else {
            return canvasBackground;
          }
        }),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: iconColor,
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: primaryColor.withAlpha(70),
        selectionHandleColor: primaryColor,
      ),
      textTheme: TextTheme(
        labelSmall: labelSmall,
        labelMedium: labelMedium,
        labelLarge: labelLarge,
        titleSmall: titleSmall,
        titleMedium: titleMedium,
        titleLarge: titleLarge,
        bodySmall: bodySmall,
        bodyMedium: bodyMedium,
        bodyLarge: bodyLarge,
      ),
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        scrolledUnderElevation: appBarScrollUnderElevation,
        shadowColor: appBarShadowColor,
        backgroundColor: appBarBackgroundColor,
        surfaceTintColor: appBarSurfaceTintColor,
      ),
      tabBarTheme: const TabBarTheme(
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        "isDarkMode": isDarkMode ? 1 : 0,
        "name": name,
        "description": description,
        "primaryColor": primaryColor.toHex(),
        "background": background.toHex(),
        "appBarBackground": appBarBackgroundColor.toHex(),
        "appBarSurfaceTintColor": appBarSurfaceTintColor.toHex(),
        "appBarShadowColor": appBarShadowColor.toHex(),
        "appBarElevation": appBarElevation,
        "appBarScrollUnderElevation": appBarScrollUnderElevation,
        "splashColor": splashColor.toHex(),
        "highlightColor": highlightColor.toHex(),
        "iconColor": iconColor.toHex(),
        "shadowColor": shadowColor.toHex(),
        "materialBackground": canvasBackground.toHex(),
        "textColor": textColor.toHex(),
        "textGrayColor": textGrayColor.toHex(),
        "textDisabledColor": textDisabledColor.toHex(),
        "buttonTextColor": buttonTextColor.toHex(),
        "buttonDisabledColor": buttonDisabledColor.toHex(),
        "dividerColor": dividerColor.toHex(),
        "tagColor": tagColor.toHex(),
        "tagBackground": tagBackground.toHex(),
        "cardBackground": cardBackground.toHex(),
      };

  factory ThemeColorData.fromJson(Map<String, dynamic> map) => ThemeColorData(
        isDarkMode: map['isDarkMode'] == 0 ? false : true,
        name: map['name'] as String,
        description: map['description'] as String,
        primaryColor: HexColor.fromHex(map['primaryColor'] as String),
        background: HexColor.fromHex(map['background'] as String),
        appBarShadowColor: HexColor.fromHex(map['appBarShadowColor'] as String),
        appBarBackgroundColor:
            HexColor.fromHex(map['appBarBackground'] as String),
        appBarSurfaceTintColor:
            HexColor.fromHex(map['appBarSurfaceTintColor'] as String),
        appBarElevation: map['appBarElevation'] as double,
        appBarScrollUnderElevation: map['appBarScrollUnderElevation'] as double,
        splashColor: HexColor.fromHex(map['splashColor'] as String),
        highlightColor: HexColor.fromHex(map['highlightColor'] as String),
        iconColor: HexColor.fromHex(map['iconColor'] as String),
        shadowColor: HexColor.fromHex(map['shadowColor'] as String),
        canvasBackground: HexColor.fromHex(map['materialBackground'] as String),
        textColor: HexColor.fromHex(map['textColor'] as String),
        textGrayColor: HexColor.fromHex(map['textGrayColor'] as String),
        textDisabledColor: HexColor.fromHex(map['textDisabledColor'] as String),
        buttonTextColor: HexColor.fromHex(map['buttonTextColor'] as String),
        buttonDisabledColor:
            HexColor.fromHex(map['buttonDisabledColor'] as String),
        dividerColor: HexColor.fromHex(map['dividerColor'] as String),
        tagColor: HexColor.fromHex(map['tagColor'] as String),
        tagBackground: HexColor.fromHex(map['tagBackground'] as String),
        cardBackground: HexColor.fromHex(map['cardBackground'] as String),
      );

  static bool isImmersive(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor ==
        Theme.of(context).canvasColor;
  }
}
