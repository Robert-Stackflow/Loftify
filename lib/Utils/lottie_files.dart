import 'package:flutter/material.dart';

import '../Widgets/Design/loftify_lottie.dart';

class LottieFiles {
  static const List<LoftifyLottieColorBinding> _loadingPalette = [
    LoftifyLottieColorBinding(
      keyPath: ['draw 3', '**', '描边 1'],
      role: LoftifyLottieColorRole.accent,
      property: LoftifyLottieColorProperty.stroke,
    ),
    LoftifyLottieColorBinding(
      keyPath: ['draw', '**', '描边 1'],
      role: LoftifyLottieColorRole.accentSecondary,
      property: LoftifyLottieColorProperty.stroke,
    ),
    LoftifyLottieColorBinding(
      keyPath: ['形状图层 1', '**', '填充 1'],
      role: LoftifyLottieColorRole.surfaceMuted,
      property: LoftifyLottieColorProperty.fill,
    ),
  ];

  static const String brightness = "assets/lottie/brightness.json";
  static const String celebrate = "assets/lottie/celebrate.json";
  static const String collectionBigNormalDark =
      "assets/lottie/collection_big_normal_dark.json";
  static const String collectionBigNormalLight =
      "assets/lottie/collection_big_normal_light.json";
  static const String collectionMediumNormalDark =
      "assets/lottie/collection_medium_normal_dark.json";
  static const String collectionMediumNormalLight =
      "assets/lottie/collection_medium_normal_light.json";
  static const String followDark = "assets/lottie/follow_dark.json";
  static const String followLight = "assets/lottie/follow_light.json";
  static const String followVideo = "assets/lottie/follow_video.json";
  static const String giftDark = "assets/lottie/gift_dark.json";
  static const String letter = "assets/lottie/letter.json";
  static const String likeBigNormalDark =
      "assets/lottie/like_big_normal_dark.json";
  static const String likeBigNormalLight =
      "assets/lottie/like_big_normal_light.json";
  static const String likeDoubleClickDark =
      "assets/lottie/like_double_click_dark.json";
  static const String likeDoubleClickLight =
      "assets/lottie/like_double_click_light.json";
  static const String likeDoubleTap = "assets/lottie/like_double_tap.json";
  static const String likeMediumDark = "assets/lottie/like_medium_dark.json";
  static const String likeMediumLight = "assets/lottie/like_medium_light.json";
  static const String likeVibrateLight =
      "assets/lottie/like_vibrate_light.json";
  static const String likeVideoNormal = "assets/lottie/like_video_normal.json";
  static const String likeVideoVibrate =
      "assets/lottie/like_video_vibrate.json";
  static const String loading01 = "assets/lottie/loading_01.json";
  static const String loading02 = "assets/lottie/loading_02.json";
  static const String loadingDark = "assets/lottie/loading_dark.json";
  static const String loadingDarkTransparent =
      "assets/lottie/loading_dark_transparent.json";
  static const String loadingGradient = "assets/lottie/loading_gradient.json";
  static const String loadingLight = "assets/lottie/loading_light.json";
  static const String moonLight = "assets/lottie/moon_light.json";
  static const String navCompass = "assets/lottie/nav_compass.json";
  static const String navHeart = "assets/lottie/nav_heart.json";
  static const String navSearch = "assets/lottie/nav_search.json";
  static const String navUser = "assets/lottie/nav_user.json";
  static const String recommendBigNormalDark =
      "assets/lottie/recommend_big_normal_dark.json";
  static const String recommendBigNormalLight =
      "assets/lottie/recommend_big_normal_light.json";
  static const String recommendBigVibrateDark =
      "assets/lottie/recommend_big_vibrate_dark.json";
  static const String recommendBigVibrateLight =
      "assets/lottie/recommend_big_vibrate_light.json";
  static const String recommendMediumFocusDark =
      "assets/lottie/recommend_medium_focus_dark.json";
  static const String recommendMediumFocusLight =
      "assets/lottie/recommend_medium_focus_light.json";
  static const String recommendVideoNormal =
      "assets/lottie/recommend_video_normal.json";
  static const String shareVideoVibrate =
      "assets/lottie/share_video_vibrate.json";
  static const String shine = "assets/lottie/shine.json";
  static const String sunLight = "assets/lottie/sun_light.json";
  static const String videoPlayingDark =
      "assets/lottie/video_playing_dark.json";
  static const String videoPlayingLight =
      "assets/lottie/video_playing_light.json";

  static const Map<String, LoftifyLottieSpec> specs = {
    brightness: LoftifyLottieSpec(
      asset: brightness,
      sourceSize: Size.square(48),
      tintRole: LoftifyLottieTintRole.foreground,
    ),
    celebrate: LoftifyLottieSpec(
      asset: celebrate,
      sourceSize: Size(1126, 2436),
      layout: LoftifyLottieLayout.effect,
    ),
    collectionBigNormalDark: LoftifyLottieSpec(
      asset: collectionBigNormalDark,
      sourceSize: Size(98, 140),
      contentBounds: Rect.fromLTWH(0, 21, 98, 98),
      opticalFill: 0.9,
    ),
    collectionBigNormalLight: LoftifyLottieSpec(
      asset: collectionBigNormalLight,
      sourceSize: Size(98, 140),
      contentBounds: Rect.fromLTWH(0, 21, 98, 98),
      opticalFill: 0.9,
    ),
    collectionMediumNormalDark: LoftifyLottieSpec(
      asset: collectionMediumNormalDark,
      sourceSize: Size.square(100),
      opticalFill: 0.9,
    ),
    collectionMediumNormalLight: LoftifyLottieSpec(
      asset: collectionMediumNormalLight,
      sourceSize: Size.square(100),
      opticalFill: 0.9,
    ),
    followDark: LoftifyLottieSpec(
      asset: followDark,
      sourceSize: Size(48, 32),
      opticalFill: 0.9,
    ),
    followLight: LoftifyLottieSpec(
      asset: followLight,
      sourceSize: Size(48, 32),
      opticalFill: 0.9,
    ),
    followVideo: LoftifyLottieSpec(
      asset: followVideo,
      sourceSize: Size(48, 32),
      opticalFill: 0.9,
    ),
    giftDark: LoftifyLottieSpec(
      asset: giftDark,
      sourceSize: Size.square(204),
      layout: LoftifyLottieLayout.effect,
      repeat: true,
    ),
    letter: LoftifyLottieSpec(
      asset: letter,
      sourceSize: Size(750, 1624),
      layout: LoftifyLottieLayout.effect,
    ),
    likeBigNormalDark: LoftifyLottieSpec(
      asset: likeBigNormalDark,
      sourceSize: Size(100, 140),
      contentBounds: Rect.fromLTWH(0, 20, 100, 100),
      opticalFill: 0.92,
    ),
    likeBigNormalLight: LoftifyLottieSpec(
      asset: likeBigNormalLight,
      sourceSize: Size(100, 140),
      contentBounds: Rect.fromLTWH(0, 20, 100, 100),
      opticalFill: 0.92,
    ),
    likeDoubleClickDark: LoftifyLottieSpec(
      asset: likeDoubleClickDark,
      sourceSize: Size(750, 500),
      layout: LoftifyLottieLayout.effect,
    ),
    likeDoubleClickLight: LoftifyLottieSpec(
      asset: likeDoubleClickLight,
      sourceSize: Size(750, 500),
      layout: LoftifyLottieLayout.effect,
    ),
    likeDoubleTap: LoftifyLottieSpec(
      asset: likeDoubleTap,
      sourceSize: Size(135, 246),
      layout: LoftifyLottieLayout.effect,
    ),
    likeMediumDark: LoftifyLottieSpec(
      asset: likeMediumDark,
      sourceSize: Size.square(100),
      opticalFill: 0.92,
    ),
    likeMediumLight: LoftifyLottieSpec(
      asset: likeMediumLight,
      sourceSize: Size.square(100),
      opticalFill: 0.92,
    ),
    likeVibrateLight: LoftifyLottieSpec(
      asset: likeVibrateLight,
      sourceSize: Size.square(72),
      opticalFill: 0.92,
      repeat: true,
    ),
    likeVideoNormal: LoftifyLottieSpec(
      asset: likeVideoNormal,
      sourceSize: Size(120, 136),
      contentBounds: Rect.fromLTWH(0, 8, 120, 120),
      opticalFill: 0.92,
    ),
    likeVideoVibrate: LoftifyLottieSpec(
      asset: likeVideoVibrate,
      sourceSize: Size.square(108),
      opticalFill: 0.92,
      repeat: true,
    ),
    loading01: LoftifyLottieSpec(
      asset: loading01,
      sourceSize: Size.square(128),
      repeat: true,
    ),
    loading02: LoftifyLottieSpec(
      asset: loading02,
      sourceSize: Size.square(128),
      repeat: true,
    ),
    loadingDark: LoftifyLottieSpec(
      asset: loadingDark,
      sourceSize: Size.square(128),
      colorBindings: _loadingPalette,
      repeat: true,
    ),
    loadingDarkTransparent: LoftifyLottieSpec(
      asset: loadingDarkTransparent,
      sourceSize: Size.square(128),
      colorBindings: _loadingPalette,
      repeat: true,
    ),
    loadingGradient: LoftifyLottieSpec(
      asset: loadingGradient,
      sourceSize: Size(750, 4),
      layout: LoftifyLottieLayout.effect,
      tintRole: LoftifyLottieTintRole.accent,
      repeat: true,
    ),
    loadingLight: LoftifyLottieSpec(
      asset: loadingLight,
      sourceSize: Size.square(128),
      colorBindings: _loadingPalette,
      repeat: true,
    ),
    moonLight: LoftifyLottieSpec(
      asset: moonLight,
      sourceSize: Size.square(48),
      tintRole: LoftifyLottieTintRole.foreground,
    ),
    navCompass: LoftifyLottieSpec(
      asset: navCompass,
      sourceSize: Size.square(48),
      opticalFill: 0.88,
    ),
    navHeart: LoftifyLottieSpec(
      asset: navHeart,
      sourceSize: Size.square(48),
      opticalFill: 0.88,
    ),
    navSearch: LoftifyLottieSpec(
      asset: navSearch,
      sourceSize: Size.square(48),
      opticalFill: 0.88,
    ),
    navUser: LoftifyLottieSpec(
      asset: navUser,
      sourceSize: Size.square(48),
      opticalFill: 0.88,
    ),
    recommendBigNormalDark: LoftifyLottieSpec(
      asset: recommendBigNormalDark,
      sourceSize: Size.square(110),
      opticalFill: 0.92,
    ),
    recommendBigNormalLight: LoftifyLottieSpec(
      asset: recommendBigNormalLight,
      sourceSize: Size(100, 140),
      contentBounds: Rect.fromLTWH(0, 20, 100, 100),
      opticalFill: 0.92,
    ),
    recommendBigVibrateDark: LoftifyLottieSpec(
      asset: recommendBigVibrateDark,
      sourceSize: Size.square(110),
      opticalFill: 0.92,
    ),
    recommendBigVibrateLight: LoftifyLottieSpec(
      asset: recommendBigVibrateLight,
      sourceSize: Size.square(110),
      opticalFill: 0.92,
    ),
    recommendMediumFocusDark: LoftifyLottieSpec(
      asset: recommendMediumFocusDark,
      sourceSize: Size.square(100),
      opticalFill: 0.92,
    ),
    recommendMediumFocusLight: LoftifyLottieSpec(
      asset: recommendMediumFocusLight,
      sourceSize: Size.square(100),
      opticalFill: 0.92,
    ),
    recommendVideoNormal: LoftifyLottieSpec(
      asset: recommendVideoNormal,
      sourceSize: Size(120, 136),
      contentBounds: Rect.fromLTWH(0, 8, 120, 120),
      opticalFill: 0.92,
    ),
    shareVideoVibrate: LoftifyLottieSpec(
      asset: shareVideoVibrate,
      sourceSize: Size.square(108),
      opticalFill: 0.92,
      repeat: true,
    ),
    shine: LoftifyLottieSpec(
      asset: shine,
      sourceSize: Size(557, 223),
      layout: LoftifyLottieLayout.effect,
    ),
    sunLight: LoftifyLottieSpec(
      asset: sunLight,
      sourceSize: Size.square(48),
      tintRole: LoftifyLottieTintRole.foreground,
    ),
    videoPlayingDark: LoftifyLottieSpec(
      asset: videoPlayingDark,
      sourceSize: Size.square(64),
      opticalFill: 0.9,
      repeat: true,
    ),
    videoPlayingLight: LoftifyLottieSpec(
      asset: videoPlayingLight,
      sourceSize: Size.square(64),
      opticalFill: 0.9,
      repeat: true,
    ),
  };

  static LoftifyLottieSpec specFor(String path) {
    return specs[path] ??
        LoftifyLottieSpec(
          asset: path,
          sourceSize: const Size.square(1),
          layout: LoftifyLottieLayout.effect,
        );
  }

  static Widget buildAnimation(
    String path, {
    Key? key,
    required double size,
    bool? autoForward,
    AnimationController? controller,
    VoidCallback? onLoaded,
    bool? repeat,
    Color? tint,
  }) {
    return Builder(
      key: key,
      builder: (context) => LoftifyLottie(
        spec: specFor(path),
        size: size,
        controller: controller,
        repeat: repeat,
        tint: tint,
        onLoaded: (_) {
          if (controller != null && autoForward == true) controller.value = 1;
          onLoaded?.call();
        },
      ),
    );
  }

  static Widget buildLoadingAnimation(double size, bool forceDark) {
    return Builder(
      builder: (context) => buildAnimation(
        getLoadingPath(context, forceDark: forceDark),
        size: size,
        repeat: true,
      ),
    );
  }

  static String getLoadingPath(
    BuildContext context, {
    bool forceDark = false,
  }) {
    return Theme.of(context).brightness == Brightness.dark || forceDark
        ? forceDark
            ? LottieFiles.loadingDarkTransparent
            : LottieFiles.loadingDark
        : LottieFiles.loadingLight;
  }
}
