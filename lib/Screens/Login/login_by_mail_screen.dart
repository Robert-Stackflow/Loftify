import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/ilogger.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Item/item_builder.dart';
import 'login_by_lofterid_screen.dart';

class LoginByMailScreen extends StatefulWidget {
  const LoginByMailScreen({super.key, this.initPassword});

  static const String routeName = "/login/mail";

  final String? initPassword;

  @override
  State<LoginByMailScreen> createState() => _LoginByMailScreenState();
}

class _LoginByMailScreenState extends State<LoginByMailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _mailController;
  late TextEditingController _passwordController;
  var mailPower = {};

  @override
  void initState() {
    super.initState();
    _mailController = TextEditingController();
    _passwordController = TextEditingController();
    _mailController.text = defaultMail;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  Future<void> _login() async {
    try {
      String mail = _mailController.text;
      String password = _passwordController.text;
      if (mail.isEmpty || password.isEmpty) {
        IToast.showTop("邮箱或密码不能为空");
        return;
      }
      var resPower = await LoginApi.getMailPower(mail);
      if (resPower['ret'] == "201") {
        mailPower = resPower['pVInfo'];
      } else {
        IToast.showTop("邮箱不存在");
        return;
      }
      var resGt = await LoginApi.loginByMailGt(mail);
      if (resGt['ret'] == "201") {
        String tk = resGt['tk'];
        var resL = await LoginApi.loginByMailL(mail, password, tk);
        if (resL['ret'] == "200") {
          IToast.showTop("登录成功");
          appProvider.token = resL['token'] ?? "";
          await RequestUtil.clearCookie();
          await HiveUtil.put(HiveUtil.userIdKey, resL['userId']);
          await HiveUtil.put(HiveUtil.tokenKey, resL['token']);
          await HiveUtil.put(HiveUtil.tokenTypeKey, TokenType.lofterID.index);
          ResponsiveUtil.returnToMainScreen(rootContext);
        } else if (resL['ret'] == "413" && resL['dt'] == "01") {
          IToast.showTop("您登录密码错误次数过多，请稍后再试");
        } else if (resL['ret'] == "413" && resL['dt'] == "02") {
          IToast.showTop("您登录密码错误次数过多，请明天再试");
        } else if (resL['ret'] == "413" && resL['dt'] == "02") {
          IToast.showTop("您的IP登录密码错误次数过多，请稍后再试");
        } else if (resL['ret'] == "413") {
          IToast.showTop("账号或密码错误");
        } else if (resL['ret'] == "447") {
          IToast.showTop("操作频繁，请稍后再试");
        } else {
          IToast.showTop("密码错误");
        }
      } else {
        IToast.showTop("未知错误");
      }
    } catch (e, t) {
      ILogger.error("Failed to login by mail", e, t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildSimpleAppBar(
          title: "邮箱登录",
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
                      hint: "输入邮箱",
                      textInputAction: TextInputAction.next,
                      controller: _mailController,
                      tailingType: TailingType.clear,
                      leadingIcon: Icons.mail_outline_rounded,
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
