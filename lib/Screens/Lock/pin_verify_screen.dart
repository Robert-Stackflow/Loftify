import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loftify/Widgets/General/Unlock/gesture_notifier.dart';
import 'package:loftify/Widgets/General/Unlock/gesture_unlock_view.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../Resources/theme.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
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

class PinVerifyScreenState extends State<PinVerifyScreen>
    with WindowListener, TrayListener {
  final String? _password = HiveUtil.getString(HiveUtil.guesturePasswdKey);
  late final bool _isUseBiometric =
      HiveUtil.getBool(HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier = GestureNotifier(
      status: GestureStatus.verify, gestureText: S.current.verifyGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();
  bool _isMaximized = false;
  bool _isStayOnTop = false;

  @override
  Future<void> onWindowResize() async {
    super.onWindowResize();
    windowManager.setMinimumSize(minimumSize);
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    HiveUtil.setWindowSize(await windowManager.getSize());
  }

  @override
  Future<void> onWindowMove() async {
    super.onWindowMove();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  Future<void> onWindowMoved() async {
    super.onWindowMoved();
    HiveUtil.setWindowPosition(await windowManager.getPosition());
  }

  @override
  void onWindowMaximize() {
    windowManager.setMinimumSize(minimumSize);
    setState(() {
      _isMaximized = true;
    });
  }

  @override
  void onWindowUnmaximize() {
    windowManager.setMinimumSize(minimumSize);
    setState(() {
      _isMaximized = false;
    });
  }

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
              ItemBuilder.buildContextMenuOverlay(
                  MainScreen(key: mainScreenKey))));
        } else {
          Navigator.of(context).pop();
        }
        _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Utils.setSafeMode(HiveUtil.getBool(HiveUtil.enableSafeModeKey,
        defaultValue: defaultEnableSafeMode));
    return Scaffold(
      backgroundColor: MyTheme.background,
      appBar: ResponsiveUtil.isDesktop() && widget.showWindowTitle
          ? PreferredSize(
              preferredSize: const Size(0, 86),
              child: ItemBuilder.buildWindowTitle(
                context,
                forceClose: true,
                leftWidgets: [const Spacer()],
                backgroundColor: MyTheme.background,
                isStayOnTop: _isStayOnTop,
                isMaximized: _isMaximized,
                onStayOnTopTap: () {
                  setState(() {
                    _isStayOnTop = !_isStayOnTop;
                    windowManager.setAlwaysOnTop(_isStayOnTop);
                  });
                },
              ),
            )
          : null,
      bottomNavigationBar: widget.showWindowTitle
          ? Container(
              height: 86,
              color: MyTheme.background,
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
                  defaultColor: Colors.grey.withOpacity(0.5),
                  selectedColor: Theme.of(context).primaryColor,
                  failedColor: Colors.redAccent,
                  disableColor: Colors.grey,
                  solidRadiusRatio: 0.3,
                  lineWidth: 2,
                  touchRadiusRatio: 0.3,
                  onCompleted: _gestureComplete,
                ),
              ),
              if (_isUseBiometric)
                ItemBuilder.buildRoundButton(
                  context,
                  text: ResponsiveUtil.isWindows()
                      ? S.current.biometricVerifyPin
                      : S.current.biometric,
                  onTap: () {
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
              gestureText: S.current.gestureLockWrong,
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
    Utils.displayApp();
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
