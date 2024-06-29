import 'package:flutter/material.dart';
import 'package:loftify/Providers/provider_manager.dart';
import 'package:loftify/Screens/Setting/apperance_setting_screen.dart';
import 'package:loftify/Screens/Setting/blacklist_setting_screen.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Screens/Setting/image_setting_screen.dart';
import 'package:loftify/Screens/Setting/lofter_basic_setting_screen.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Screens/Setting/userdynamicshield_setting_screen.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
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
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.setting, context: context, transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.basicSetting),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.generalSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const GeneralSettingScreen());
                },
                leading: Icons.settings_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.apprearanceSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const AppearanceSettingScreen());
                },
                leading: Icons.color_lens_outlined,
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.imageSetting,
                showLeading: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const ImageSettingScreen());
                },
                leading: Icons.image_outlined,
              ),
              // ItemBuilder.buildEntryItem(
              //   context: context,
              //   title: S.current.operationSetting,
              //   showLeading: true,
              //   onTap: () {
              //     RouteUtil.pushCupertinoRoute(
              //         context, const OperationSettingScreen());
              //   },
              //   leading: Icons.touch_app_outlined,
              // ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.experimentSetting,
                showLeading: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const ExperimentSettingScreen());
                },
                leading: Icons.flag_outlined,
              ),
              if (ProviderManager.globalProvider.token.isEmpty)
                const SizedBox(height: 10),
              if (ProviderManager.globalProvider.token.isEmpty) _buildAbout(),
              if (ProviderManager.globalProvider.token.isNotEmpty)
                ..._buildLofter(),
              if (ProviderManager.globalProvider.token.isNotEmpty)
                ..._buildLogout(),
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
      bottomRadius: true,
      topRadius: true,
      showLeading: true,
      padding: 15,
      onTap: () {
        RouteUtil.pushCupertinoRoute(context, const AboutSettingScreen());
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
        // description: "版权保护、礼物设置",
        onTap: () {
          RouteUtil.pushCupertinoRoute(
              context, const LofterBasicSettingScreen());
        },
        leading: Icons.copyright_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        title: S.current.blacklistSetting,
        onTap: () {
          RouteUtil.pushCupertinoRoute(context, const BlacklistSettingScreen());
        },
        leading: Icons.block_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        title: S.current.tagShieldSetting,
        onTap: () {
          RouteUtil.pushCupertinoRoute(context, const TagShieldSettingScreen());
        },
        leading: Icons.tag_rounded,
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        bottomRadius: true,
        title: S.current.userDynamicShieldSetting,
        onTap: () {
          RouteUtil.pushCupertinoRoute(
              context, const UserDynamicShieldSettingScreen());
        },
        leading: Icons.shield_outlined,
      ),
    ];
  }

  List<Widget> _buildLogout() {
    return [
      const SizedBox(height: 10),
      _buildAbout(),
      const SizedBox(height: 10),
      ItemBuilder.buildEntryItem(
        context: context,
        showLeading: true,
        topRadius: true,
        bottomRadius: true,
        title: "退出登录",
        onTap: () async {
          CustomConfirmDialog.showAnimatedFromBottom(
            context,
            message: "是否退出登录？",
            confirmButtonText: S.current.confirm,
            cancelButtonText: S.current.cancel,
            onTapConfirm: () async {
              ProviderManager.globalProvider.token = "";
              await HiveUtil.delete(key: HiveUtil.userIdKey);
              await HiveUtil.delete(key: HiveUtil.tokenKey);
              await HiveUtil.delete(key: HiveUtil.deviceIdKey);
              await RequestUtil.getInstance().clearCookie();
              HiveUtil.delete(key: HiveUtil.tokenTypeKey).then((value) {
                Navigator.pop(context);
                IToast.showTop(context, text: "退出成功");
                Utils.returnToMainScreen(context);
              });
            },
            onTapCancel: () {
              Navigator.pop(context);
            },
            customDialogType: CustomDialogType.custom,
          );
        },
        leading: Icons.exit_to_app_rounded,
      ),
    ];
  }
}
