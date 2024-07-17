import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Models/constant.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Models/login_response.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_lofterid_screen.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';

import '../../Providers/provider_manager.dart';
import '../../Utils/request_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Item/item_builder.dart';

class LoginByPasswordScreen extends StatefulWidget {
  const LoginByPasswordScreen({super.key, this.initPhone, this.initPassword});

  static const String routeName = "/login/password";

  final String? initPhone;
  final String? initPassword;

  @override
  State<LoginByPasswordScreen> createState() => _LoginByPasswordScreenState();
}

class _LoginByPasswordScreenState extends State<LoginByPasswordScreen>
    with TickerProviderStateMixin {
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _passwordController = TextEditingController();
    _mobileController.text = widget.initPhone ?? defaultPhone;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  void _login() {
    String mobile = _mobileController.text;
    String password = _passwordController.text;
    if (mobile.isEmpty || password.isEmpty) {
      IToast.showTop(context, text: "手机号或密码不能为空");
      return;
    }
    LoginApi.loginByPassword(mobile, password).then((value) async {
      LoginResponse loginResponse = LoginResponse.fromJson(value);
      if (loginResponse.result != 0) {
        IToast.showTop(context, text: loginResponse.desc);
      } else {
        IToast.showTop(context, text: "登录成功");
        ProviderManager.globalProvider.token = loginResponse.token ?? "";
        await RequestUtil.getInstance().clearCookie();
        await HiveUtil.put(
            key: HiveUtil.userIdKey, value: loginResponse.userid);
        await HiveUtil.put(key: HiveUtil.tokenKey, value: loginResponse.token);
        await HiveUtil.put(
            key: HiveUtil.deviceIdKey, value: loginResponse.deviceid);
        await HiveUtil.put(
            key: HiveUtil.tokenTypeKey, value: TokenType.password.index);
        ResponsiveUtil.returnToMainScreen(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
          title: "密码登录",
          context: context,
          leading: Icons.close_rounded,
          transparent: true,
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
                      hint: "输入手机号",
                      textInputAction: TextInputAction.next,
                      controller: _mobileController,
                      tailingType: TailingType.clear,
                      leadingIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    ItemBuilder.buildInputItem(
                      context: context,
                      hint: "输入密码",
                      textInputAction: TextInputAction.next,
                      leadingIcon: Icons.verified_outlined,
                      controller: _passwordController,
                      tailingType: TailingType.password,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      child: ItemBuilder.buildRoundButton(
                        context,
                        text: "登录",
                        background: Theme.of(context).primaryColor,
                        onTap: _login,
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
                      text: "其他登录方式",
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ItemBuilder.buildSmallIcon(
                            context: context,
                            icon: Icons.phone_android_rounded,
                            onTap: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByCaptchaScreen(
                                    initPhone: _mobileController.text),
                              );
                            }),
                        const SizedBox(width: 30),
                        ItemBuilder.buildSmallIcon(
                            context: context,
                            icon: Icons.card_membership_rounded,
                            onTap: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByLofterIDScreen(
                                  initPassword: _passwordController.text,
                                ),
                              );
                            }),
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
