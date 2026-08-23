import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Models/login_response.dart';
import 'package:loftify/Screens/Login/login_by_lofterid_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:window_manager/window_manager.dart';

import '../../Models/simple_response.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/login_input_item.dart';
import '../../l10n/l10n.dart';

class LoginByCaptchaScreen extends StatefulWidget {
  const LoginByCaptchaScreen({super.key, this.initPhone});

  static const String routeName = "/login/captcha";

  final String? initPhone;

  @override
  State<LoginByCaptchaScreen> createState() => _LoginByCaptchaScreenState();
}

class _LoginByCaptchaScreenState extends BaseDynamicState<LoginByCaptchaScreen>
    with TickerProviderStateMixin, WindowListener {
  late TextEditingController _mobileController;
  late TextEditingController _captchaController;
  late TextEditingController _captchaCodeController;
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _photoCaptchaFocusNode = FocusNode();
  final FocusNode _captchaCodeFocusNode = FocusNode();
  Timer? _captchaTimer;
  dynamic _photoCaptcha;
  bool _isFetchingCaptchaCode = false;
  String _captchaText = appLocalizations.getCaptcha;

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

  @override
  void dispose() {
    _captchaTimer?.cancel();
    WindowManager.instance.removeListener(this);
    _mobileController.dispose();
    _captchaController.dispose();
    _captchaCodeController.dispose();
    _mobileFocusNode.dispose();
    _photoCaptchaFocusNode.dispose();
    _captchaCodeFocusNode.dispose();
    super.dispose();
  }

  void _refreshPhotoCaptcha() {
    LoginApi.getPhotoCaptcha().then((value) {
      if (!mounted) return;
      setState(() {
        _photoCaptcha = value;
      });
    });
  }

  void _fetchCaptchaCode() {
    String mobile = _mobileController.text;
    String captcha = _captchaController.text;
    if (mobile.isEmpty) {
      IToast.showTop(appLocalizations.phoneCannotBeEmpty);
      return;
    }
    if (captcha.isEmpty) {
      IToast.showTop(appLocalizations.imageCaptchaCannotBeEmpty);
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
          _captchaText = appLocalizations.resendAfterSeconds(60);
        });
        _captchaTimer?.cancel();
        _captchaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (timer.tick == 60) {
            timer.cancel();
            if (mounted) {
              setState(() {
                _isFetchingCaptchaCode = false;
                _captchaText = appLocalizations.getCaptcha;
                _refreshPhotoCaptcha();
                _captchaController.text = "";
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _captchaText =
                    appLocalizations.resendAfterSeconds(60 - timer.tick);
              });
            }
          }
        });
        IToast.showTop(appLocalizations.sendCaptchaSuccess);
      }
    });
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    String mobile = _mobileController.text;
    String password = _captchaCodeController.text;
    if (mobile.isEmpty || password.isEmpty) {
      IToast.showTop(appLocalizations.phoneOrCodeCaptchaCannotBeEmpty);
      return;
    }
    LoginApi.loginByCaptchaCode(mobile, password).then((value) async {
      LoginResponse loginResponse = LoginResponse.fromJson(value);
      if (loginResponse.result != 0) {
        IToast.showTop(loginResponse.desc);
        _refreshPhotoCaptcha();
      } else {
        IToast.showTop(appLocalizations.loginSuccess);
        appProvider.token = loginResponse.token ?? "";
        await RequestUtil.clearCookie();
        await ChewieHiveUtil.put(HiveUtil.userIdKey, loginResponse.userid);
        await ChewieHiveUtil.put(HiveUtil.tokenKey, loginResponse.token);
        await ChewieHiveUtil.put(HiveUtil.deviceIdKey, loginResponse.deviceid);
        await ChewieHiveUtil.put(
            HiveUtil.tokenTypeKey, TokenType.captchCode.index);
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
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ResponsiveAppBar(
          title: appLocalizations.loginByCaptcha,
          showBack: !ResponsiveUtil.isLandscapeLayout(),
          leadingIcon: Icons.close_rounded,
          onTapBack: () => Navigator.maybeOf(context)?.maybePop(),
          showBorder: false,
          titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
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
                    LoginInputItem(
                      hint: appLocalizations.inputPhone,
                      textInputAction: TextInputAction.next,
                      controller: _mobileController,
                      focusNode: _mobileFocusNode,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      onSubmitted: (_) => _photoCaptchaFocusNode.requestFocus(),
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.clear,
                      ),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: Icons.phone_android_rounded,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    LoginInputItem(
                      hint: appLocalizations.inputImageCaptcha,
                      textInputAction: TextInputAction.next,
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: Icons.verified_outlined,
                      ),
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.widget,
                        widget: _photoCaptcha != null
                            ? GestureDetector(
                                onTap: () {
                                  _refreshPhotoCaptcha();
                                },
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  child: Image.memory(_photoCaptcha,
                                      width: 80, height: 40),
                                ),
                              )
                            : const SizedBox(width: 80, height: 40),
                      ),
                      controller: _captchaController,
                      focusNode: _photoCaptchaFocusNode,
                      onSubmitted: (_) => _captchaCodeFocusNode.requestFocus(),
                      keyboardType: TextInputType.number,
                    ),
                    LoginInputItem(
                      hint: appLocalizations.inputCodeCaptcha,
                      textInputAction: TextInputAction.done,
                      controller: _captchaCodeController,
                      focusNode: _captchaCodeFocusNode,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onSubmitted: (_) => _login(),
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.text,
                        text: _captchaText,
                        enable: !_isFetchingCaptchaCode,
                        onTap: _fetchCaptchaCode,
                      ),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: Icons.password_rounded,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      child: RoundIconTextButton(
                        text: appLocalizations.login,
                        onPressed: _login,
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
                      text: appLocalizations.otherLoginMethods,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ToolButton(
                            context: context,
                            icon: Icons.password_rounded,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByPasswordScreen(
                                  initPhone: _mobileController.text,
                                ),
                              );
                            }),
                        const SizedBox(width: 30),
                        ToolButton(
                            context: context,
                            icon: Icons.card_membership_rounded,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                const LoginByLofterIDScreen(),
                              );
                            }),
                        // const SizedBox(width: 30),
                        // ToolButton(
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
