import 'package:flutter/cupertino.dart';
import 'package:loftify/Utils/utils.dart';

class AssetUtil {
  static const String avatar = "assets/avatar.png";
  static const String collectionDarkIcon = "assets/icon/collection_dark.png";
  static const String collectionLightIcon = "assets/icon/collection_light.png";
  static const String collectionPrimaryIcon =
      "assets/icon/collection_primary.png";
  static const String collectionWhiteIcon = "assets/icon/collection_white.png";
  static const String confirmIcon = "assets/icon/confirm.png";
  static const String downloadWhiteIcon = "assets/icon/download_white.png";
  static const String dressDarkIcon = "assets/icon/dress_dark.png";
  static const String dressLightIcon = "assets/icon/dress_light.png";
  static const String dynamicDarkIcon = "assets/icon/dynamic_dark.png";
  static const String dynamicDarkSelectedIcon =
      "assets/icon/dynamic_dark_selected.png";
  static const String dynamicLightIcon = "assets/icon/dynamic_light.png";
  static const String dynamicLightSelectedIcon =
      "assets/icon/dynamic_light_selected.png";
  static const String favoriteDarkIcon = "assets/icon/favorite_dark.png";
  static const String favoriteLightIcon = "assets/icon/favorite_light.png";
  static const String grainWhiteIcon = "assets/icon/grain_white.png";
  static const String homeDarkIcon = "assets/icon/home_dark.png";
  static const String homeDarkSelectedIcon =
      "assets/icon/home_dark_selected.png";
  static const String homeLightIcon = "assets/icon/home_light.png";
  static const String homeLightSelectedIcon =
      "assets/icon/home_light_selected.png";
  static const String hotIcon = "assets/icon/hot.png";
  static const String hotlessIcon = "assets/icon/hotless.png";
  static const String hottestIcon = "assets/icon/hottest.png";
  static const String hotWhiteIcon = "assets/icon/hot_white.png";
  static const String infoIcon = "assets/icon/info.png";
  static const String likeDarkIcon = "assets/icon/like_dark.png";
  static const String likeFilledIcon = "assets/icon/like_filled.png";
  static const String likeLightIcon = "assets/icon/like_light.png";
  static const String linkDarkIcon = "assets/icon/link_dark.png";
  static const String linkGreyIcon = "assets/icon/link_grey.png";
  static const String linkLightIcon = "assets/icon/link_light.png";
  static const String linkPrimaryIcon = "assets/icon/link_primary.png";
  static const String linkWhiteIcon = "assets/icon/link_white.png";
  static const String mineDarkIcon = "assets/icon/mine_dark.png";
  static const String mineDarkSelectedIcon =
      "assets/icon/mine_dark_selected.png";
  static const String mineLightIcon = "assets/icon/mine_light.png";
  static const String mineLightSelectedIcon =
      "assets/icon/mine_light_selected.png";
  static const String orderDownDarkIcon = "assets/icon/order_down_dark.png";
  static const String orderDownLightIcon = "assets/icon/order_down_light.png";
  static const String orderUpDarkIcon = "assets/icon/order_up_dark.png";
  static const String orderUpLightIcon = "assets/icon/order_up_light.png";
  static const String searchDarkIcon = "assets/icon/search_dark.png";
  static const String searchGreyIcon = "assets/icon/search_grey.png";
  static const String searchLightIcon = "assets/icon/search_light.png";
  static const String settingDarkIcon = "assets/icon/setting_dark.png";
  static const String settingLightIcon = "assets/icon/setting_light.png";
  static const String tagDarkIcon = "assets/icon/tag_dark.png";
  static const String tagGreyIcon = "assets/icon/tag_grey.png";
  static const String tagLightIcon = "assets/icon/tag_light.png";
  static const String tagWhiteIcon = "assets/icon/tag_white.png";
  static const String pinDarkIcon = "assets/icon/pin_dark.png";
  static const String pinLightIcon = "assets/icon/pin_light.png";

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

  static const String emptyMess = "assets/mess/empty.png";
  static const String tagIconBgMess = "assets/mess/tag_icon_bg.png";
  static const String tagRowBgMess = "assets/mess/tag_row_bg.png";
  static const String tagRowBgDarkMess = "assets/mess/tag_row_bg_dark.png";

  static load(
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

  static loadDouble(
    BuildContext context,
    String light,
    String dark, {
    double size = 24,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return Image.asset(
      Utils.isDark(context) ? dark : light,
      fit: fit,
      width: width ?? size,
      height: height ?? size,
    );
  }

  static loadDecorationImage(
    String path, {
    BoxFit? fit,
  }) {
    return DecorationImage(
      image: AssetImage(path),
      fit: fit,
    );
  }
}
