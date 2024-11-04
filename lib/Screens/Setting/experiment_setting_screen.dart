import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../Utils/app_provider.dart';
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
      HiveUtil.getBool(HiveUtil.enableGuesturePasswdKey);
  bool _hasGuesturePasswd =
      HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
          HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
  bool _autoLock = HiveUtil.getBool(HiveUtil.autoLockKey);
  bool _enableSafeMode =
      HiveUtil.getBool(HiveUtil.enableSafeModeKey, defaultValue: false);
  bool _enableBiometric = HiveUtil.getBool(HiveUtil.enableBiometricKey);
  bool _biometricAvailable = false;
  int _refreshRate = HiveUtil.getInt(HiveUtil.refreshRateKey);
  List<DisplayMode> _modes = [];
  DisplayMode? _activeMode;
  DisplayMode? _preferredMode;

  List<Tuple2<String, DisplayMode>> get _supportedModeTuples =>
      _modes.map((e) => Tuple2(e.toString(), e)).toList();

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
    if (ResponsiveUtil.isAndroid()) getRefreshRate();
  }

  getRefreshRate() async {
    _modes = await FlutterDisplayMode.supported;
    _activeMode = await FlutterDisplayMode.active;
    _preferredMode = await FlutterDisplayMode.preferred;
    ILogger.info(
        "Current active display mode: $_activeMode\nCurrent preferred display mode: $_preferredMode");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItemBuilder.buildDesktopAppBar(
        transparent: true,
        title: S.current.experimentSetting,
        context: context,
        showBack: true,
        background: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: EasyRefresh(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          children: [
            if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
            ..._privacySettings(),
            if (ResponsiveUtil.isAndroid()) const SizedBox(height: 10),
            if (ResponsiveUtil.isAndroid())
              ItemBuilder.buildEntryItem(
                // tip: _modes.isNotEmpty
                //     ? _modes[_refreshRate.clamp(0, _modes.length - 1)]
                //         .toString()
                //     : "",
                context: context,
                title: "刷新率",
                description:
                    "意在解决部分机型高刷失效的问题，如无问题，请不要修改\n如果您的设备支持LTPO，可能会设置失败\n已选模式: ${_modes.isNotEmpty ? _modes[_refreshRate.clamp(0, _modes.length - 1)].toString() : ""}\n首选模式: ${_preferredMode?.toString() ?? "Unknown"}\n活动模式: ${_activeMode?.toString() ?? "Unknown"}",
                topRadius: true,
                bottomRadius: true,
                onTap: () {
                  getRefreshRate();
                  BottomSheetBuilder.showListBottomSheet(
                    context,
                    (context) => TileList.fromOptions(
                      _supportedModeTuples,
                      (item2) async {
                        try {
                          ILogger.info(
                              "Try to set display mode: ${item2.toString()}");
                          ILogger.info(
                              "Active display mode before set: ${_activeMode.toString()}\nPreferred display mode before set: ${_preferredMode.toString()}");
                          await FlutterDisplayMode.setPreferredMode(item2);
                          _activeMode = await FlutterDisplayMode.active;
                          _preferredMode = await FlutterDisplayMode.preferred;
                          ILogger.info(
                              "Active display mode after set: ${_activeMode.toString()}\nPreferred display mode after set: ${_preferredMode.toString()}");
                          if (_preferredMode?.toString() != item2.toString()) {
                            IToast.showTop("刷新率设置失败");
                          } else {
                            if (_activeMode?.toString() != item2.toString()) {
                              IToast.showTop("刷新率设置成功，但当前显示模式未改变");
                            } else {
                              IToast.showTop("刷新率设置成功");
                            }
                          }
                        } catch (e, t) {
                          IToast.showTop("刷新率设置失败: ${e.toString()}");
                          ILogger.error("Failed to set display mode", e, t);
                        }
                        _refreshRate = _modes.indexOf(item2);
                        getRefreshRate();
                        HiveUtil.put(HiveUtil.refreshRateKey, _refreshRate);
                        Navigator.pop(context);
                      },
                      selected:
                          _modes[_refreshRate.clamp(0, _modes.length - 1)],
                      context: context,
                      title: "选择刷新率",
                      onCloseTap: () => Navigator.pop(context),
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  _privacySettings() {
    return [
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
          disabled: ResponsiveUtil.isMacOS() || ResponsiveUtil.isLinux(),
          title: "生物识别",
          description: "仅支持Android、IOS、Windows设备；Windows设备上仅支持PIN",
          onTap: onBiometricTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd,
        child: ItemBuilder.buildRadioItem(
          context: context,
          value: _autoLock,
          title: "处于后台自动锁定",
          description: "在Windows、Linux、MacOS设备中，窗口最小化或最小化至托盘时即表示处于后台",
          onTap: onEnableAutoLockTapped,
        ),
      ),
      Visibility(
        visible: _enableGuesturePasswd && _hasGuesturePasswd && _autoLock,
        child: Selector<AppProvider, int>(
          selector: (context, globalProvider) => globalProvider.autoLockTime,
          builder: (context, autoLockTime, child) => ItemBuilder.buildEntryItem(
            context: context,
            title: "自动锁定时机",
            tip: AppProvider.getAutoLockOptionLabel(autoLockTime),
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (context) => TileList.fromOptions(
                  AppProvider.getAutoLockOptions(),
                  (item2) {
                    appProvider.autoLockTime = item2;
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
        disabled: ResponsiveUtil.isDesktop(),
        bottomRadius: true,
        description: "仅支持Android、IOS设备；当软件进入最近任务列表页面，隐藏页面内容；同时禁用应用内截图",
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
      RouteUtil.pushPanelCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            setState(() {
              _enableGuesturePasswd = !_enableGuesturePasswd;
              IToast.showTop(_enableGuesturePasswd ? "手势密码启用成功" : "手势密码关闭成功");
              HiveUtil.put(
                  HiveUtil.enableGuesturePasswdKey, _enableGuesturePasswd);
              _hasGuesturePasswd =
                  HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
                      HiveUtil.getString(HiveUtil.guesturePasswdKey)!
                          .isNotEmpty;
            });
          },
          isModal: false,
        ),
      );
    });
  }

  onBiometricTapped() {
    if (!_enableBiometric) {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            IToast.showTop("生物识别开启成功");
            setState(() {
              _enableBiometric = !_enableBiometric;
              HiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _enableBiometric = !_enableBiometric;
        HiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
      });
    }
  }

  onChangePinTapped() {
    setState(() {
      RouteUtil.pushPanelCupertinoRoute(context, const PinChangeScreen());
      //     .then((value) {
      //   setState(() {
      //     _hasGuesturePasswd =
      //         HiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      //             HiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
      //   });
      // });
    });
  }

  onEnableAutoLockTapped() {
    setState(() {
      _autoLock = !_autoLock;
      HiveUtil.put(HiveUtil.autoLockKey, _autoLock);
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
      HiveUtil.put(HiveUtil.enableSafeModeKey, _enableSafeMode);
    });
  }
}
