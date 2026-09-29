import 'dart:math';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  static const String routeName = "/pin/change";

  @override
  PinChangeScreenState createState() => PinChangeScreenState();
}

class PinChangeScreenState extends BaseDynamicState<PinChangeScreen> {
  String _gesturePassword = "";
  final String? _oldPassword =
      ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey);
  bool _isEditMode =
      ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey) != null &&
          ChewieHiveUtil.getString(HiveUtil.guesturePasswdKey)!.isNotEmpty;
  late final bool _isUseBiometric =
      _isEditMode && ChewieHiveUtil.getBool(HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier = _isEditMode
      ? GestureNotifier(
          status: GestureStatus.verify,
          gestureText: appLocalizations.drawOldGestureLock)
      : GestureNotifier(
          status: GestureStatus.create,
          gestureText: appLocalizations.drawNewGestureLock);
  final GlobalKey<GestureState> _gestureUnlockView = GlobalKey();
  final GlobalKey<GestureUnlockIndicatorState> _indicator = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (_isUseBiometric) {
      auth();
    }
  }

  void auth() async {
    await Utils.localAuth(onAuthed: () {
      IToast.showTop(appLocalizations.biometricVerifySuccess);
      setState(() {
        _notifier.setStatus(
          status: GestureStatus.create,
          gestureText: appLocalizations.drawNewGestureLock,
        );
        _isEditMode = false;
      });
      _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = mediaSize.width < 360 || textScale > 1.35;
    final gestureSize = (compact
            ? min(240.0, max(0.0, mediaSize.width - 32))
            : min(mediaSize.width, 400))
        .toDouble();
    return Scaffold(
      appBar: ResponsiveAppBar(showBack: true),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 16 : 28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: max(
                  0,
                  constraints.maxHeight - (compact ? 32 : 56),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _notifier.gestureText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: compact ? 12 : 24),
                  GestureUnlockIndicator(
                    key: _indicator,
                    size: 30,
                    roundSpace: 4,
                    defaultColor: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                    selectedColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  ),
                  SizedBox(height: compact ? 8 : 14),
                  SizedBox.square(
                    dimension: gestureSize,
                    child: GestureUnlockView(
                      key: _gestureUnlockView,
                      size: gestureSize,
                      padding: compact ? 44 : 60,
                      roundSpace: compact ? 32 : 40,
                      defaultColor: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5),
                      selectedColor: Theme.of(context).primaryColor,
                      failedColor: Theme.of(context).colorScheme.error,
                      disableColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      solidRadiusRatio: 0.3,
                      lineWidth: 2,
                      touchRadiusRatio: 0.3,
                      onCompleted: _gestureComplete,
                    ),
                  ),
                  if (_isEditMode && _isUseBiometric) ...[
                    SizedBox(height: compact ? 12 : 20),
                    RoundIconTextButton(
                      text: ResponsiveUtil.isWindows()
                          ? appLocalizations.biometricVerifyPin
                          : appLocalizations.biometric,
                      onPressed: () {
                        auth();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _gestureComplete(List<int> selected, UnlockStatus status) async {
    switch (_notifier.status) {
      case GestureStatus.create:
      case GestureStatus.createFailed:
        if (selected.length < 4) {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.createFailed,
              gestureText: appLocalizations.atLeast4Points,
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verify,
              gestureText: appLocalizations.drawGestureLockAgain,
            );
          });
          _gesturePassword = GestureUnlockView.selectedToString(selected);
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.success);
          _indicator.currentState?.setSelectPoint(selected);
        }
        break;
      case GestureStatus.verify:
      case GestureStatus.verifyFailed:
        if (!_isEditMode) {
          String password = GestureUnlockView.selectedToString(selected);
          if (_gesturePassword == password) {
            IToast.showTop(appLocalizations.setGestureLockSuccess);
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verify,
                gestureText: appLocalizations.setGestureLockSuccess,
              );
              Navigator.pop(context);
            });
            ChewieHiveUtil.put(HiveUtil.guesturePasswdKey,
                GestureUnlockView.selectedToString(selected));
            appProvider.pinSettled = HiveUtil.hasGuesturePasswd();
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: appLocalizations.gestureLockNotMatch,
              );
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
          }
        } else {
          String password = GestureUnlockView.selectedToString(selected);
          if (_oldPassword == password) {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.create,
                gestureText: appLocalizations.drawNewGestureLock,
              );
              _isEditMode = false;
            });
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
        }
        break;
      case GestureStatus.verifyFailedCountOverflow:
        break;
    }
  }
}
