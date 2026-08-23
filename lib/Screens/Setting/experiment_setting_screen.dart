import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/display_mode_util.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';
import '../Lock/pin_change_screen.dart';
import '../Lock/pin_verify_screen.dart';
import 'base_setting_screen.dart';

class ExperimentSettingScreen extends BaseSettingScreen {
  const ExperimentSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/experiment";

  @override
  State<ExperimentSettingScreen> createState() =>
      _ExperimentSettingScreenState();
}

class _ExperimentSettingScreenState
    extends BaseDynamicState<ExperimentSettingScreen>
    with TickerProviderStateMixin {
  bool _enableGuesturePasswd =
      ChewieHiveUtil.getBool(HiveUtil.enableGuesturePasswdKey);
  bool _autoLock = ChewieHiveUtil.getBool(HiveUtil.autoLockKey);
  bool _enableSafeMode =
      ChewieHiveUtil.getBool(HiveUtil.enableSafeModeKey, defaultValue: false);
  bool _enableBiometric = ChewieHiveUtil.getBool(HiveUtil.enableBiometricKey);
  bool _biometricAvailable = false;
  List<DisplayMode> _modes = [];
  DisplayMode? _selectedMode;
  DisplayMode? _activeMode;
  DisplayMode? _preferredMode;

  @override
  void initState() {
    super.initState();
    initBiometricAuthentication();
    if (ResponsiveUtil.isAndroid()) getRefreshRate();
  }

  Future<void> getRefreshRate() async {
    try {
      final supportedModes = await FlutterDisplayMode.supported;
      final activeMode = await FlutterDisplayMode.active;
      final preferredMode = await FlutterDisplayMode.preferred;
      final selectedMode = DisplayModePreference.resolve(
        modes: supportedModes,
        activeMode: activeMode,
        encodedMode: ChewieHiveUtil.getString(HiveUtil.refreshRateModeKey),
        legacyIndex: ChewieHiveUtil.getInt(
          HiveUtil.refreshRateKey,
          defaultValue: -1,
        ),
      );
      ILogger.info(
          "Current active display mode: $activeMode\nCurrent preferred display mode: $preferredMode");
      if (!mounted) return;
      setState(() {
        _modes = DisplayModePreference.ordered(supportedModes);
        _activeMode = activeMode;
        _preferredMode = preferredMode;
        _selectedMode = selectedMode;
      });
    } catch (error, stackTrace) {
      ILogger.error("Failed to load display modes", error, stackTrace);
      if (mounted) {
        IToast.showTop(
          appLocalizations.setRefreshRateFailedWithError(error.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.experimentSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        Selector<AppProvider, bool>(
          selector: (context, globalProvider) => globalProvider.pinSettled,
          builder: (context, pinSettled, child) => _privacySettings(pinSettled),
        ),
        if (ResponsiveUtil.isAndroid()) ...[
          _fpsSettings(),
        ],
      ],
    );
  }

  Widget _fpsSettings() {
    String modeLabel(DisplayMode mode) => DisplayModePreference.label(
          mode,
          automaticLabel: appLocalizations.followSystem,
        );
    final selectedMode = _selectedMode;
    return CaptionItem(
      title: appLocalizations.refreshRate,
      children: [
        InlineSelectionItem<SelectionItemModel<DisplayMode>>(
            title: appLocalizations.refreshRate,
            description: appLocalizations.refreshRateDescription(
              selectedMode == null ? "" : modeLabel(selectedMode),
              _preferredMode == null ? "Unknown" : modeLabel(_preferredMode!),
              _activeMode == null ? "Unknown" : modeLabel(_activeMode!),
            ),
            items: _modes
                .map((mode) => SelectionItemModel(modeLabel(mode), mode))
                .toList(),
            initItem: selectedMode == null
                ? null
                : SelectionItemModel(modeLabel(selectedMode), selectedMode),
            hint: appLocalizations.chooseRefreshRate,
            onChanged: (item) async {
              if (item == null) return;
              final mode = item.value;
              try {
                ILogger.info("Try to set display mode: $mode");
                await DisplayModeController.setPreferredMode(mode);
                await ChewieHiveUtil.put(
                  HiveUtil.refreshRateModeKey,
                  DisplayModePreference.encode(mode),
                );
                await ChewieHiveUtil.delete(HiveUtil.refreshRateKey);
                final activeMode = await FlutterDisplayMode.active;
                final preferredMode = await FlutterDisplayMode.preferred;
                if (!mounted) return;
                setState(() {
                  _selectedMode = mode;
                  _activeMode = activeMode;
                  _preferredMode = preferredMode;
                });
                if (preferredMode != mode) {
                  IToast.showTop(appLocalizations.setRefreshRateFailed);
                } else if (activeMode != mode) {
                  IToast.showTop(
                    appLocalizations
                        .setRefreshRateSuccessWithDisplayModeNotChanged,
                  );
                } else {
                  IToast.showTop(appLocalizations.setRefreshRateSuccess);
                }
              } catch (error, stackTrace) {
                IToast.showTop(
                  appLocalizations
                      .setRefreshRateFailedWithError(error.toString()),
                );
                ILogger.error("Failed to set display mode", error, stackTrace);
              }
              await getRefreshRate();
            }),
      ],
    );
  }

  Widget _privacySettings(bool pinSettled) {
    return CaptionItem(
      title: appLocalizations.privacySetting,
      children: [
        CheckboxItem(
          value: _enableGuesturePasswd,
          title: appLocalizations.enableGestureLock,
          onTap: onEnablePinTapped,
        ),
        Visibility(
          visible: _enableGuesturePasswd,
          child: EntryItem(
            title: pinSettled
                ? appLocalizations.changeGestureLock
                : appLocalizations.setGestureLock,
            description:
                pinSettled ? "" : appLocalizations.haveToSetGestureLockTip,
            onTap: onChangePinTapped,
          ),
        ),
        Visibility(
          visible: _enableGuesturePasswd && pinSettled && _biometricAvailable,
          child: CheckboxItem(
            value: _enableBiometric,
            disabled: ResponsiveUtil.isMacOS() || ResponsiveUtil.isLinux(),
            title: appLocalizations.biometric,
            description: appLocalizations.biometricUnlockTip,
            onTap: onBiometricTapped,
          ),
        ),
        Visibility(
          visible: _enableGuesturePasswd && pinSettled,
          child: CheckboxItem(
            value: _autoLock,
            title: appLocalizations.autoLock,
            description: appLocalizations.autoLockTip,
            onTap: onEnableAutoLockTapped,
          ),
        ),
        Visibility(
          visible: _enableGuesturePasswd && pinSettled && _autoLock,
          child: Selector<AppProvider, int>(
            selector: (context, globalProvider) =>
                globalProvider.autoLockSeconds,
            builder: (context, autoLockTime, child) =>
                InlineSelectionItem<SelectionItemModel<int>>(
              title: appLocalizations.autoLockDelay,
              items: AppProvider.getAutoLockOptions()
                  .map((option) =>
                      SelectionItemModel(option.item1, option.item2))
                  .toList(),
              initItem: SelectionItemModel(
                AppProvider.getAutoLockOptionLabel(autoLockTime),
                autoLockTime,
              ),
              hint: appLocalizations.chooseAutoLockDelay,
              onChanged: (item) {
                if (item != null) appProvider.autoLockSeconds = item.value;
              },
            ),
          ),
        ),
        CheckboxItem(
          value: _enableSafeMode,
          title: appLocalizations.safeMode,
          disabled: ResponsiveUtil.isDesktop(),
          roundBottom: true,
          description: appLocalizations.safeModeTip,
          onTap: onSafeModeTapped,
        ),
      ],
    );
  }

  Future<void> initBiometricAuthentication() async {
    final localAuth = LocalAuthentication();
    final available = await localAuth.canCheckBiometrics;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
    });
  }

  void onEnablePinTapped() {
    setState(() {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            setState(() {
              _enableGuesturePasswd = !_enableGuesturePasswd;
              IToast.showTop(_enableGuesturePasswd
                  ? appLocalizations.enableGestureLockSuccess
                  : appLocalizations.disableGestureLockSuccess);
              ChewieHiveUtil.put(
                  HiveUtil.enableGuesturePasswdKey, _enableGuesturePasswd);
            });
          },
          isModal: false,
        ),
      );
    });
  }

  void onBiometricTapped() {
    if (!_enableBiometric) {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        PinVerifyScreen(
          onSuccess: () {
            IToast.showTop(appLocalizations.enableBiometricSuccess);
            setState(() {
              _enableBiometric = !_enableBiometric;
              ChewieHiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
            });
          },
          isModal: false,
        ),
      );
    } else {
      setState(() {
        _enableBiometric = !_enableBiometric;
        ChewieHiveUtil.put(HiveUtil.enableBiometricKey, _enableBiometric);
      });
    }
  }

  void onChangePinTapped() {
    setState(() {
      RouteUtil.pushPanelCupertinoRoute(context, const PinChangeScreen());
      //     .then((value) {
      //   setState(() {
      //     _hasGuesturePasswd =
      //         ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
      //             ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
      //   });
      // });
    });
  }

  void onEnableAutoLockTapped() {
    setState(() {
      _autoLock = !_autoLock;
      ChewieHiveUtil.put(HiveUtil.autoLockKey, _autoLock);
    });
  }

  void onSafeModeTapped() {
    setState(() {
      _enableSafeMode = !_enableSafeMode;
      if (ResponsiveUtil.isMobile()) {
        if (_enableSafeMode) {
          FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        } else {
          FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        }
      }
      ChewieHiveUtil.put(HiveUtil.enableSafeModeKey, _enableSafeMode);
    });
  }
}
