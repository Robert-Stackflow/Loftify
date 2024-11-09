import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/apperance_setting_screen.dart';
import 'package:loftify/Screens/Setting/blacklist_setting_screen.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Screens/Setting/image_setting_screen.dart';
import 'package:loftify/Screens/Setting/lofter_basic_setting_screen.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Screens/Setting/userdynamicshield_setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';

import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import 'about_setting_screen.dart';
import 'experiment_setting_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  static const String routeName = "/setting";

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildResponsiveAppBar(
          showBack: true,
          transparent: true,
          title: S.current.setting,
          context: context,
          background: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.basicSetting),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.generalSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushPanelCupertinoRoute(context,
                      GeneralSettingScreen(key: generalSettingScreenKey));
                },
                leading: Icons.settings_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.appearanceSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushPanelCupertinoRoute(
                      context, const AppearanceSettingScreen());
                },
                leading: Icons.color_lens_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.imageSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushPanelCupertinoRoute(
                      context, const ImageSettingScreen());
                },
                leading: Icons.image_outlined,
              ),
              // ItemBuilder.buildEntryItem(
              //   context: context,
              //   title: S.current.operationSetting,
              //   showLeading: true,
              //   onTap: () {
              //     RouteUtil.pushPanelCupertinoRoute(
              //         context, const OperationSettingScreen());
              //   },
              //   leading: Icons.touch_app_outlined,
              // ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.experimentSetting,
                showLeading: true,
                roundBottom: true,
                onTap: () {
                  RouteUtil.pushPanelCupertinoRoute(
                      context, const ExperimentSettingScreen());
                },
                leading: Icons.flag_outlined,
              ),
              if (appProvider.token.isNotEmpty) ..._buildLofter(),
              const SizedBox(height: 10),
              _buildAbout(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _buildAbout() {
    return ItemBuilder.buildEntryItem(
      context: context,
      title: S.current.about,
      roundBottom: true,
      roundTop: true,
      showLeading: true,
      padding: 15,
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(context, const AboutSettingScreen());
      },
      leading: Icons.info_outline_rounded,
    );
  }

  List<Widget> _buildLofter() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.lofterSetting),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        title: S.current.lofterBasicSetting,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, const LofterBasicSettingScreen());
        },
        leading: Icons.copyright_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        title: S.current.blacklistSetting,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, const BlacklistSettingScreen());
        },
        leading: Icons.block_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        title: S.current.tagShieldSetting,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, const TagShieldSettingScreen());
        },
        leading: Icons.tag_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        roundBottom: true,
        title: S.current.userDynamicShieldSetting,
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
              context, const UserDynamicShieldSettingScreen());
        },
        leading: Icons.shield_outlined,
      ),
    ];
  }
}
