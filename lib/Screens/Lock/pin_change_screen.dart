import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/General/Unlock/gesture_notifier.dart';
import 'package:loftify/Widgets/General/Unlock/gesture_unlock_indicator.dart';
import 'package:loftify/Widgets/General/Unlock/gesture_unlock_view.dart';

import '../../Utils/hive_util.dart';

class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key});

  static const String routeName = "/pin/change";

  @override
  PinChangeScreenState createState() => PinChangeScreenState();
}

AndroidAuthMessages andStrings = const AndroidAuthMessages(
  cancelButton: '取消',
  goToSettingsButton: '去设置',
  biometricNotRecognized: '指纹识别失败',
  goToSettingsDescription: '请设置指纹',
  biometricHint: '',
  biometricSuccess: '指纹识别成功',
  signInTitle: '指纹验证',
  deviceCredentialsRequiredTitle: '请先录入指纹!',
);

class PinChangeScreenState extends State<PinChangeScreen> {
  String _gesturePassword = "";
  final String? _oldPassword =
      HiveUtil.getString(key: HiveUtil.guesturePasswdKey);
  bool _isEditMode =
      HiveUtil.getString(key: HiveUtil.guesturePasswdKey) != null &&
          HiveUtil.getString(key: HiveUtil.guesturePasswdKey)!.isNotEmpty;
  late final bool _isUseBiometric =
      _isEditMode && HiveUtil.getBool(key: HiveUtil.enableBiometricKey);
  late final GestureNotifier _notifier = _isEditMode
      ? GestureNotifier(status: GestureStatus.verify, gestureText: "绘制旧手势密码")
      : GestureNotifier(status: GestureStatus.create, gestureText: "绘制新手势密码");
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
    LocalAuthentication localAuth = LocalAuthentication();
    try {
      await localAuth
          .authenticate(
              localizedReason: '进行指纹验证以使用APP',
              authMessages: [andStrings, andStrings, andStrings],
              options: const AuthenticationOptions(
                  biometricOnly: true,
                  useErrorDialogs: false,
                  stickyAuth: true))
          .then((value) {
        if (value) {
          IToast.showTop( "验证成功");
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.create,
              gestureText: "绘制新手势密码",
            );
            _isEditMode = false;
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        IPrint.debug("not avaliable");
      } else if (e.code == auth_error.notEnrolled) {
        IPrint.debug("not enrolled");
      } else if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        IPrint.debug("locked out");
      } else {
        IPrint.debug("other reason:$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        right: false,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _notifier.gestureText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 30),
              GestureUnlockIndicator(
                key: _indicator,
                size: 30,
                roundSpace: 4,
                defaultColor: Colors.grey.withOpacity(0.5),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
              Expanded(
                child: GestureUnlockView(
                  key: _gestureUnlockView,
                  size: MediaQuery.sizeOf(context).width,
                  padding: 60,
                  roundSpace: 40,
                  defaultColor: Colors.grey.withOpacity(0.5),
                  selectedColor: Theme.of(context).primaryColor,
                  failedColor: Theme.of(context).colorScheme.error,
                  disableColor: Colors.grey,
                  solidRadiusRatio: 0.3,
                  lineWidth: 2,
                  touchRadiusRatio: 0.3,
                  onCompleted: _gestureComplete,
                ),
              ),
              Visibility(
                visible: _isEditMode,
                child: Visibility(
                  visible: _isUseBiometric,
                  child: GestureDetector(
                    onTap: () {
                      auth();
                    },
                    child: Text(
                      "指纹识别",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
            ],
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
              gestureText: "连接数不能小于4个，请重新设置",
            );
          });
          _gestureUnlockView.currentState?.updateStatus(UnlockStatus.failed);
        } else {
          setState(() {
            _notifier.setStatus(
              status: GestureStatus.verify,
              gestureText: "请再次绘制解锁密码",
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
            IToast.showTop( "设置成功");
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verify,
                gestureText: "设置成功",
              );
              Navigator.pop(context);
            });
            HiveUtil.put(
                key: HiveUtil.guesturePasswdKey,
                value: GestureUnlockView.selectedToString(selected));
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: "与上一次绘制不一致, 请重新绘制",
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
                gestureText: "绘制新手势密码",
              );
              _isEditMode = false;
            });
            _gestureUnlockView.currentState?.updateStatus(UnlockStatus.normal);
          } else {
            setState(() {
              _notifier.setStatus(
                status: GestureStatus.verifyFailed,
                gestureText: "密码错误, 请重新绘制",
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
