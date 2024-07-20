import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';

import '../../Models/login_lofterid_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Item/item_builder.dart';

class LoginByLofterIDScreen extends StatefulWidget {
  const LoginByLofterIDScreen({super.key, this.initPassword});

  static const String routeName = "/login/lofterID";

  final String? initPassword;

  @override
  State<LoginByLofterIDScreen> createState() => _LoginByLofterIDScreenState();
}

class _LoginByLofterIDScreenState extends State<LoginByLofterIDScreen>
    with TickerProviderStateMixin {
  late TextEditingController _lofterIDController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _lofterIDController = TextEditingController();
    _passwordController = TextEditingController();
    _lofterIDController.text = defaultLofterID;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  void _login() {
    String lofterID = _lofterIDController.text;
    String password = _passwordController.text;
    if (lofterID.isEmpty || password.isEmpty) {
      IToast.showTop("LofterID或密码不能为空");
      return;
    }
    LoginApi.loginByLofterID(lofterID, password).then((value) async {
      LoginLofterIDResponse loginResponse =
          LoginLofterIDResponse.fromJson(value);
      if (loginResponse.status != 200) {
        IToast.showTop(loginResponse.desc);
      } else {
        IToast.showTop("登录成功");
        appProvider.token = loginResponse.token ?? "";
        await RequestUtil.getInstance().clearCookie();
        await HiveUtil.put(
            key: HiveUtil.userIdKey, value: loginResponse.userId);
        await HiveUtil.put(key: HiveUtil.tokenKey, value: loginResponse.token);
        await HiveUtil.put(
            key: HiveUtil.tokenTypeKey, value: TokenType.lofterID.index);
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
          title: "LofterID登录",
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
                      hint: "输入LofterID",
                      textInputAction: TextInputAction.next,
                      controller: _lofterIDController,
                      tailingType: TailingType.clear,
                      leadingIcon: Icons.card_membership_rounded,
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
                                const LoginByCaptchaScreen(),
                              );
                            }),
                        const SizedBox(width: 30),
                        ItemBuilder.buildSmallIcon(
                            context: context,
                            icon: Icons.password_rounded,
                            onTap: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByPasswordScreen(
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
