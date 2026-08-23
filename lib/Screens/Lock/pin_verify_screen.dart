import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../main_screen.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({
    super.key,
    this.onSuccess,
    this.isModal = true,
    this.jumpToMain = false,
    this.showWindowTitle = false,
    this.autoAuth = true,
  });

  final bool isModal;
  final bool autoAuth;
  final bool showWindowTitle;
  final bool jumpToMain;
  final Function()? onSuccess;
  static const String routeName = "/pin/verify";

  @override
  PinVerifyScreenState createState() => PinVerifyScreenState();
}

class PinVerifyScreenState extends BaseWindowState<PinVerifyScreen>
    with TrayListener {
  final String? _password =
      ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey);
  late final bool _isUseBiometric =
      ChewieHiveUtil.getBool(HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier = GestureNotifier(
      status: GestureStatus.verify,
      gestureText: appLocalizations.verifyGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();

  @override
  void dispose() {
    super.dispose();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }

  @override
  void initState() {
    if (widget.jumpToMain) {
      trayManager.addListener(this);
      Utils.initSimpleTray();
    }
    windowManager.addListener(this);
    super.initState();
    if (_isUseBiometric && widget.autoAuth) {
      auth();
    }
  }

  void auth() async {
    Utils.localAuth(
      onAuthed: () {
        if (widget.onSuccess != null) widget.onSuccess!();
        if (widget.jumpToMain) {
          Navigator.of(context).pushReplacement(RouteUtil.getFadeRoute(
              CustomMouseRegion(child: MainScreen(key: mainScreenKey))));
        } else {
          Navigator.of(context).pop();
        }
        _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ChewieUtils.setSafeMode(ChewieHiveUtil.getBool(HiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    return Scaffold(
      backgroundColor: ChewieTheme.background,
      appBar: ResponsiveUtil.isDesktop() && widget.showWindowTitle
          ? PreferredSize(
              preferredSize: const Size(0, 86),
              child: WindowTitleWrapper(
                forceClose: true,
                leftWidgets: const [Spacer()],
                backgroundColor: ChewieTheme.background,
                isStayOnTop: isStayOnTop,
                isMaximized: isMaximized,
                onStayOnTopTap: () {
                  setState(() {
                    isStayOnTop = !isStayOnTop;
                    windowManager.setAlwaysOnTop(isStayOnTop);
                  });
                },
              ),
            )
          : null,
      bottomNavigationBar: widget.showWindowTitle
          ? Container(
              height: 86,
              color: ChewieTheme.background,
            )
          : null,
      body: Center(
        child: PopScope(
          canPop: !widget.isModal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                _notifier.gestureText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              Flexible(
                child: GestureUnlockView(
                  key: _gestureUnlockView,
                  size: min(MediaQuery.sizeOf(context).width, 400),
                  padding: 60,
                  roundSpace: 40,
                  defaultColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5),
                  selectedColor: Theme.of(context).primaryColor,
                  failedColor: Theme.of(context).colorScheme.error,
                  disableColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  solidRadiusRatio: 0.3,
                  lineWidth: 2,
                  touchRadiusRatio: 0.3,
                  onCompleted: _gestureComplete,
                ),
              ),
              if (_isUseBiometric)
                RoundIconTextButton(
                  text: ResponsiveUtil.isWindows()
                      ? appLocalizations.biometricVerifyPin
                      : appLocalizations.biometric,
                  onPressed: () {
                    auth();
                  },
                ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  void _gestureComplete(List<int> selected, UnlockStatus status) async {
    switch (_notifier.status) {
      case GestureStatus.verify:
      case GestureStatus.verifyFailed:
        String password = GestureUnlockView.selectedToString(selected);
        if (_password == password) {
          if (widget.onSuccess != null) widget.onSuccess!();
          Navigator.pop(context);
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verifyFailed,
              gestureText: appLocalizations.gestureLockWrong,
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
      case GestureStatus.create:
      case GestureStatus.createFailed:
        break;
    }
  }

  @override
  void onTrayIconMouseDown() {
    ChewieUtils.displayApp();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    Utils.processTrayMenuItemClick(context, menuItem, true);
  }
}
