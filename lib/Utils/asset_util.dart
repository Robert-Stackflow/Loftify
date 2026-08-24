import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/widgets.dart';

class AssetUtil {
  static const String avatar = "assets/avatar.png";

  static const String collectionDarkIllust =
      "assets/illust/collection_dark.webp";
  static const String collectionLightIllust =
      "assets/illust/collection_light.webp";
  static const String dressDarkIllust = "assets/illust/dress_dark.webp";
  static const String dressLightIllust = "assets/illust/dress_light.webp";
  static const String favoriteDarkIllust = "assets/illust/favorite_dark.png";
  static const String favoriteLightIllust = "assets/illust/favorite_light.png";
  static const String flagDarkIllust = "assets/illust/flag_dark.webp";
  static const String flagDark2Illust = "assets/illust/flag_dark_2.webp";
  static const String flagLightIllust = "assets/illust/flag_light.webp";
  static const String flagLight2Illust = "assets/illust/flag_light_2.webp";
  static const String hotDarkIllust = "assets/illust/hot_dark.webp";
  static const String hotLightIllust = "assets/illust/hot_light.webp";
  static const String likeDarkIllust = "assets/illust/like_dark.png";
  static const String likeLightIllust = "assets/illust/like_light.png";
  static const String lofterDarkIllust = "assets/illust/lofter_dark.png";
  static const String lofterLightIllust = "assets/illust/lofter_light.png";
  static const String pigeonDarkIllust = "assets/illust/pigeon_dark.png";
  static const String pigeonLightIllust = "assets/illust/pigeon_light.png";
  static const String starDarkIllust = "assets/illust/star_dark.png";
  static const String starLightIllust = "assets/illust/star_light.png";
  static const String tagDarkIllust = "assets/illust/tag_dark.webp";
  static const String tagLightIllust = "assets/illust/tag_light.webp";
  static const String thumbDarkIllust = "assets/illust/thumb_dark.png";
  static const String thumbLightIllust = "assets/illust/thumb_light.png";

  static const String tagIconBgMess = "assets/mess/tag_icon_bg.png";
  static const String tagRowBgMess = "assets/mess/tag_row_bg.png";
  static const String tagRowBgDarkMess = "assets/mess/tag_row_bg_dark.png";

  static Widget load(
    String path, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      path,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static Widget loadDouble(
    BuildContext context,
    String light,
    String dark, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      ColorUtil.isDark(context) ? dark : light,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static DecorationImage loadDecorationImage(
    String path, {
    BoxFit? fit,
  }) {
    return DecorationImage(
      image: AssetImage(path),
      fit: fit,
    );
  }
}
