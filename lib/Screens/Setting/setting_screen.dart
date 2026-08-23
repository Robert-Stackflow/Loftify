import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/apperance_setting_screen.dart';
import 'package:loftify/Screens/Setting/blacklist_setting_screen.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Screens/Setting/image_setting_screen.dart';
import 'package:loftify/Screens/Setting/lofter_basic_setting_screen.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Screens/Setting/userdynamicshield_setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';

import '../../l10n/l10n.dart';
import 'about_setting_screen.dart';
import 'base_setting_screen.dart';
import 'experiment_setting_screen.dart';

class SettingScreen extends BaseSettingScreen {
  const SettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends BaseDynamicState<SettingScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.setting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.basicSetting,
          children: [
            EntryItem(
              context: context,
              title: appLocalizations.generalSetting,
              showLeading: true,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(context,
                    GeneralSettingScreen(key: generalSettingScreenKey));
              },
              leading: Icons.settings_outlined,
            ),
            EntryItem(
              context: context,
              title: appLocalizations.appearanceSetting,
              showLeading: true,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                    context, const AppearanceSettingScreen());
              },
              leading: Icons.color_lens_outlined,
            ),
            EntryItem(
              context: context,
              title: appLocalizations.imageSetting,
              showLeading: true,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                    context, const ImageSettingScreen());
              },
              leading: Icons.image_outlined,
            ),
            EntryItem(
              context: context,
              title: appLocalizations.experimentSetting,
              showLeading: true,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                    context, const ExperimentSettingScreen());
              },
              leading: Icons.flag_outlined,
            ),
          ],
        ),
        if (appProvider.token.isNotEmpty) _buildLofter(),
        _buildAbout(),
      ],
    );
  }

  Widget _buildAbout() {
    return CaptionItem(
      context: context,
      title: appLocalizations.other,
      children: [
        EntryItem(
          context: context,
          title: appLocalizations.about,
          showLeading: true,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
                context, const AboutSettingScreen());
          },
          leading: Icons.info_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildLofter() {
    return CaptionItem(
      context: context,
      title: appLocalizations.lofterSetting,
      children: [
        EntryItem(
          context: context,
          showLeading: true,
          title: appLocalizations.lofterBasicSetting,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
                context, const LofterBasicSettingScreen());
          },
          leading: Icons.copyright_rounded,
        ),
        EntryItem(
          context: context,
          showLeading: true,
          title: appLocalizations.blacklistSetting,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
                context, const BlacklistSettingScreen());
          },
          leading: Icons.block_rounded,
        ),
        EntryItem(
          context: context,
          showLeading: true,
          title: appLocalizations.tagShieldSetting,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
                context, const TagShieldSettingScreen());
          },
          leading: Icons.tag_rounded,
        ),
        EntryItem(
          context: context,
          showLeading: true,
          title: appLocalizations.userDynamicShieldSetting,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
                context, const UserDynamicShieldSettingScreen());
          },
          leading: Icons.shield_outlined,
        ),
      ],
    );
  }
}
