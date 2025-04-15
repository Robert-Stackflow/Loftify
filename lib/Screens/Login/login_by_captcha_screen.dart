import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Models/login_response.dart';
import 'package:loftify/Screens/Login/login_by_lofterid_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/simple_response.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class LoginByCaptchaScreen extends StatefulWidget {
  const LoginByCaptchaScreen({super.key, this.initPhone});

  static const String routeName = "/login/captcha";

  final String? initPhone;

  @override
  State<LoginByCaptchaScreen> createState() => _LoginByCaptchaScreenState();
}

class _LoginByCaptchaScreenState extends State<LoginByCaptchaScreen>
    with TickerProviderStateMixin, WindowListener {
  late TextEditingController _mobileController;
  late TextEditingController _captchaController;
  late TextEditingController _captchaCodeController;
  dynamic _photoCaptcha;
  bool _isFetchingCaptchaCode = false;
  String _captchaText = S.current.getCaptcha;

  @override
  void initState() {
    WindowManager.instance.addListener(this);
    super.initState();
    _mobileController = TextEditingController();
    _captchaController = TextEditingController();
    _captchaCodeController = TextEditingController();
    _mobileController.text = widget.initPhone ?? defaultPhone;
    _refreshPhotoCaptcha();
  }

  void _refreshPhotoCaptcha() {
    LoginApi.getPhotoCaptcha().then((value) {
      setState(() {
        _photoCaptcha = value;
      });
    });
  }

  void _fetchCaptchaCode() {
    String mobile = _mobileController.text;
    String captcha = _captchaController.text;
    if (mobile.isEmpty) {
      IToast.showTop(S.current.phoneCannotBeEmpty);
      return;
    }
    if (captcha.isEmpty) {
      IToast.showTop(S.current.imageCaptchaCannotBeEmpty);
      return;
    }
    LoginApi.getCaptchaCode(mobile, captcha).then((value) {
      SimpleResponse simpleResponse = SimpleResponse.fromJson(value);
      if (simpleResponse.result != 0) {
        IToast.showTop(simpleResponse.desc);
        _refreshPhotoCaptcha();
      } else {
        _isFetchingCaptchaCode = true;
        setState(() {
          _captchaText = S.current.resendAfterSeconds(60);
        });
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (timer.tick == 60) {
            timer.cancel();
            if (mounted) {
              setState(() {
                _isFetchingCaptchaCode = false;
                _captchaText = S.current.getCaptcha;
                _refreshPhotoCaptcha();
                _captchaController.text = "";
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _captchaText = S.current.resendAfterSeconds(60 - timer.tick);
              });
            }
          }
        });
        IToast.showTop(S.current.sendCaptchaSuccess);
      }
    });
  }

  void _login() {
    String mobile = _mobileController.text;
    String password = _captchaCodeController.text;
    if (mobile.isEmpty || password.isEmpty) {
      IToast.showTop(S.current.phoneOrCodeCaptchaCannotBeEmpty);
      return;
    }
    LoginApi.loginByCaptchaCode(mobile, password).then((value) async {
      LoginResponse loginResponse = LoginResponse.fromJson(value);
      if (loginResponse.result != 0) {
        IToast.showTop(loginResponse.desc);
        _refreshPhotoCaptcha();
      } else {
        IToast.showTop(S.current.loginSuccess);
        appProvider.token = loginResponse.token ?? "";
        await RequestUtil.clearCookie();
        await HiveUtil.put(HiveUtil.userIdKey, loginResponse.userid);
        await HiveUtil.put(HiveUtil.tokenKey, loginResponse.token);
        await HiveUtil.put(HiveUtil.deviceIdKey, loginResponse.deviceid);
        await HiveUtil.put(HiveUtil.tokenTypeKey, TokenType.captchCode.index);
        mainScreenState?.login();
      }
    });
  }

  Future<void> persist(LoginResponse loginResponse) async {}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
          title: S.current.loginByCaptcha,
          context: context,
          leadingIcon: Icons.close_rounded,
          transparent: true,
          titleLeftMargin: ResponsiveUtil.isLandscape() ? 15 : 5,
          showLeading: !ResponsiveUtil.isLandscape(),
        ),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              ScrollConfiguration(
                behavior: NoShadowScrollBehavior(),
                child: ListView(
                  children: [
                    const SizedBox(height: 50),
                    ItemBuilder.buildInputItem(
                      context: context,
                      hint: S.current.inputPhone,
                      textInputAction: TextInputAction.next,
                      controller: _mobileController,
                      tailingType: TailingType.clear,
                      leadingIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      hint: S.current.inputImageCaptcha,
                      textInputAction: TextInputAction.next,
                      leadingIcon: Icons.verified_outlined,
                      controller: _captchaController,
                      tailingType: TailingType.widget,
                      keyboardType: TextInputType.number,
                      tailingWidget: _photoCaptcha != null
                          ? GestureDetector(
                              onTap: () {
                                _refreshPhotoCaptcha();
                              },
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                child: Image.memory(_photoCaptcha,
                                    width: 80, height: 40),
                              ),
                            )
                          : const SizedBox(width: 80, height: 40),
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      hint: S.current.inputCodeCaptcha,
                      textInputAction: TextInputAction.next,
                      controller: _captchaCodeController,
                      tailingType: TailingType.text,
                      tailingText: _captchaText,
                      leadingIcon: Icons.password_rounded,
                      tailingEnable: !_isFetchingCaptchaCode,
                      onTailingTap: _fetchCaptchaCode,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      child: ItemBuilder.buildRoundButton(
                        context,
                        text: S.current.login,
                        onTap: _login,
                        background: Theme.of(context).primaryColor,
                        color: Colors.white,
                        fontSizeDelta: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 50,
                child: Column(
                  children: [
                    ItemBuilder.buildTextDivider(
                      context: context,
                      text: S.current.otherLoginMethods,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ItemBuilder.buildSmallIcon(
                            context: context,
                            icon: Icons.password_rounded,
                            onTap: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByPasswordScreen(
                                  initPhone: _mobileController.text,
                                ),
                              );
                            }),
                        const SizedBox(width: 30),
                        ItemBuilder.buildSmallIcon(
                            context: context,
                            icon: Icons.card_membership_rounded,
                            onTap: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                const LoginByLofterIDScreen(),
                              );
                            }),
                        // const SizedBox(width: 30),
                        // ItemBuilder.buildSmallIcon(
                        //     context: context,
                        //     icon: Icons.mail_outline_rounded,
                        //     onTap: () {
                        //       RouteUtil.pushCupertinoRoute(
                        //         context,
                        //         const LoginByMailScreen(),
                        //       );
                        //     }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
