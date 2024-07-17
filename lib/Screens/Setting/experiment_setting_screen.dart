import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loftify/Screens/Setting/fontweight_screen.dart';
import 'package:provider/provider.dart';

import '../../Providers/global_provider.dart';
import '../../Providers/provider_manager.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';

class ExperimentSettingScreen extends StatefulWidget {
  const ExperimentSettingScreen({super.key});

  static const String routeName = "/setting/experiment";

  @override
  State<ExperimentSettingScreen> createState() =>
      _ExperimentSettingScreenState();
}

class _ExperimentSettingScreenState extends State<ExperimentSettingScreen>
    with TickerProviderStateMixin {
  bool _enableGuesturePasswd =
      HiveUtil.getBool(key: HiveUtil.enableGuesturePasswdKey);
  bool _hasGuesturePasswd =
      HiveUtil.getString(key: HiveUtil.guesturePasswdKey) != null &&
          HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!.isNotEmpty;
  bool _autoLock = HiveUtil.getBool(key: HiveUtil.autoLockKey);
  bool _enableSafeMode =
      HiveUtil.getBool(key: HiveUtil.enableSafeModeKey, defaultValue: false);
  bool _enableBiometric = HiveUtil.getBool(key: HiveUtil.enableBiometricKey);
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.experimentSetting,
            context: context,
            transparent: true),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isMobile()) ..._privacySettings(),
              const SizedBox(height: 10),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "查看字重",
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  RouteUtil.pushCupertinoRoute(
                      context, const FontWeightScreen());
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _privacySettings() {
    return [
      const SizedBox(height: 10),
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.privacySetting),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _enableGuesturePasswd,
        title: "启用手势密码",
        onTap: onEnablePinTapped,
      ),
      Visibility(
        visible: _enableGuesturePasswd,
        child: ItemBuilder.buildEntryItem(
          context: context,
          title: _hasGuesturePasswd ? "更改手势密码" : "设置手势密码",
          description: _hasGuesturePasswd ? "" : "设置手势密码后才能使用锁定功能",
          onTap: onChangePinTapped,
        ),
      ),
      Visibility(
        visible:
            _enableGuesturePasswd && _hasGuesturePasswd && _biometricAvailable,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _enableBiometric,
          title: "生物识别",
          onTap: onBiometricTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _autoLock,
          title: "处于后台自动锁定",
          onTap: onEnableAutoLockTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd && _autoLock,
        child: Selector<GlobalProvider, int>(
          selector: (context, globalProvider) => globalProvider.autoLockTime,
          builder: (context, autoLockTime, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: "自动锁定时机",
            tip: GlobalProvider.getAutoLockOptionLabel(autoLockTime),
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (context) => TileList.fromOptions(
                  GlobalProvider.getAutoLockOptions(),
                  (item2) {
                    ProviderManager.globalProvider.autoLockTime = item2;
                    Navigator.pop(context);
                  },
                  selected: autoLockTime,
                  context: context,
                  title: "选择自动锁定时机",
                  onCloseTap: () => Navigator.pop(context),
                ),
              );
            },
          ),
        ),
      ),
      ItemBuilder.buildRadioItem(
        context: context,
        value: _enableSafeMode,
        title: "安全模式",
        bottomRadius: true,
        description: "当软件进入最近任务列表页面，隐藏页面内容；同时禁用应用内截图",
        onTap: onSafeModeTapped,
      ),
    ];
  }

  initBiometricAuthentication() async {
    LocalAuthentication localAuth = LocalAuthentication();
    bool available = await localAuth.canCheckBiometrics;
    setState(() {
      _biometricAvailable = available;
    });
  }

  onEnablePinTapped() {
    setState(() {
      if (_enableGuesturePasswd) {
        RouteUtil.pushCupertinoRoute(
          context,
          PinVerifyScreen(
            onSuccess: () {
              IToast.showTop(context, text: "手势密码关闭成功");
              setState(() {
                _enableGuesturePasswd = !_enableGuesturePasswd;
                HiveUtil.put(
                    key: HiveUtil.enableGuesturePasswdKey,
                    value: _enableGuesturePasswd);
                _hasGuesturePasswd =
                    HiveUtil.getString(key: HiveUtil.guesturePasswdKey) !=
                            null &&
                        HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!
                            .isNotEmpty;
              });
            },
            isModal: false,
          ),
        );
      } else {
        setState(() {
          _enableGuesturePasswd = !_enableGuesturePasswd;
          HiveUtil.put(
              key: HiveUtil.enableGuesturePasswdKey,
              value: _enableGuesturePasswd);
          _hasGuesturePasswd =
              HiveUtil.getString(key: HiveUtil.guesturePasswdKey) != null &&
                  HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!
                      .isNotEmpty;
        });
      }
    });
  }

  onBiometricTapped() {
    if (!_enableBiometric) {
      RouteUtil.pushCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            IToast.showTop(context, text: "生物识别开启成功");
            setState(() {
              _enableBiometric = !_enableBiometric;
              HiveUtil.put(
                  key: HiveUtil.enableBiometricKey, value: _enableBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _enableBiometric = !_enableBiometric;
        HiveUtil.put(key: HiveUtil.enableBiometricKey, value: _enableBiometric);
      });
    }
  }

  onChangePinTapped() {
    setState(() {
      RouteUtil.pushCupertinoRoute(context, const PinChangeScreen())
          .then((value) {
        setState(() {
          _hasGuesturePasswd =
              HiveUtil.getString(key: HiveUtil.guesturePasswdKey) != null &&
                  HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!
                      .isNotEmpty;
        });
      });
    });
  }

  onEnableAutoLockTapped() {
    setState(() {
      _autoLock = !_autoLock;
      HiveUtil.put(key: HiveUtil.autoLockKey, value: _autoLock);
    });
  }

  onSafeModeTapped() {
    setState(() {
      _enableSafeMode = !_enableSafeMode;
      if (ResponsiveUtil.isMobile()) {
        if (_enableSafeMode) {
          FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        } else {
          FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        }
      }
      HiveUtil.put(key: HiveUtil.enableSafeModeKey, value: _enableSafeMode);
    });
  }
}
