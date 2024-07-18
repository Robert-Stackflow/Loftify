import 'package:flutter/cupertino.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:tuple/tuple.dart';

import '../Utils/font_util.dart';
import '../Utils/hive_util.dart';
import '../Utils/itoast.dart';
import '../Utils/utils.dart';
import '../Widgets/Dialog/progress_dialog.dart';

enum FontEnum {
  Default(fontName: '跟随系统', fontFamily: '', fontUrl: ''),
  LxgwWenKai(
      fontName: '霞鹜文楷',
      fontFamily: 'LxgwWenKai',
      fontUrl:
          'https://github.com/lxgw/LxgwWenKai/releases/download/v1.330/LXGWWenKai-Regular.ttf'),
  LxgwWenKaiGB(
      fontName: '霞鹜文楷-GB',
      fontFamily: 'LxgwWenKaiGB',
      fontUrl:
          'https://github.com/lxgw/LxgwWenkaiGB/releases/download/v1.330/LXGWWenKaiGB-Regular.ttf'),
  LxgwWenKaiLite(
      fontName: '霞鹜文楷-Lite',
      fontFamily: 'LxgwWenKaiLite',
      fontUrl:
          'https://github.com/lxgw/LxgwWenKai-Lite/releases/download/v1.330/LXGWWenKaiLite-Regular.ttf'),
  LxgwWenKaiScreen(
      fontName: '霞鹜文楷-Screen',
      fontFamily: 'LxgwWenKaiScreen',
      fontUrl:
          'https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v1.330/LXGWWenKaiGBScreen.ttf');

  const FontEnum({
    required this.fontName,
    required this.fontFamily,
    required this.fontUrl,
  });

  final String fontName;
  final String fontFamily;
  final String fontUrl;

  static List<Tuple2<String, FontEnum>> getFontList() {
    return FontEnum.values.map((e) => Tuple2(e.fontName, e)).toList();
  }

  static String getFontUrlByEnum(FontEnum fontEnum) {
    return fontEnum.fontUrl;
  }

  static String getFontUrlByFontFamily(String fontFamily) {
    return FontEnum.values
        .firstWhere((e) => e.fontFamily == fontFamily)
        .fontUrl;
  }

  static getCurrentFont() {
    return FontEnum.values[Utils.patchEnum(
      HiveUtil.getInt(key: HiveUtil.fontFamilyKey, defaultValue: 0),
      FontEnum.values.length,
    )];
  }

  static downloadFont({
    BuildContext? context,
    bool showToast = true,
    Function(bool)? onFinished,
    Function(double)? onReceiveProgress,
    FontEnum? fontEnum,
  }) async {
    fontEnum ??= getCurrentFont();
    if (fontEnum != FontEnum.Default) {
      await FontUtil.url(
        fontFamily: fontEnum!.fontFamily,
        url: fontEnum.fontUrl,
      ).load(onReceiveProgress: onReceiveProgress).then((value) {
        onFinished?.call(value);
        if (showToast && context != null) {
          if (value == true) {
            IToast.showTop( "字体加载成功，重启后切换");
          } else {
            IToast.showTop( "字体加载失败");
          }
        }
      });
    } else {
      onFinished?.call(true);
      return Future(() => true);
    }
  }

  static void loadFont(BuildContext context, FontEnum item,
      {bool autoRestartApp = false}) async {
    var dialog = showProgressDialog(context, msg: "已下载");
    await HiveUtil.put(key: HiveUtil.fontFamilyKey, value: item.index);
    await FontEnum.downloadFont(
      context: context,
      onFinished: (value) {
        dialog.dismiss();
        if (autoRestartApp) {
          ResponsiveUtil.restartApp(context);
        }
      },
      onReceiveProgress: (progress) {
        dialog.updateProgress(progress: progress);
      },
    );
  }
}
