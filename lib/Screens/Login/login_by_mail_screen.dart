import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/login_input_item.dart';
import '../../l10n/l10n.dart';
import 'login_by_lofterid_screen.dart';

class LoginByMailScreen extends StatefulWidget {
  const LoginByMailScreen({super.key, this.initPassword});

  static const String routeName = "/login/mail";

  final String? initPassword;

  @override
  State<LoginByMailScreen> createState() => _LoginByMailScreenState();
}

class _LoginByMailScreenState extends BaseDynamicState<LoginByMailScreen>
    with TickerProviderStateMixin {
  late TextEditingController _mailController;
  late TextEditingController _passwordController;
  final FocusNode _mailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  var mailPower = {};

  @override
  void initState() {
    super.initState();
    _mailController = TextEditingController();
    _passwordController = TextEditingController();
    _mailController.text = defaultMail;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  @override
  void dispose() {
    _mailController.dispose();
    _passwordController.dispose();
    _mailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      String mail = _mailController.text;
      String password = _passwordController.text;
      if (mail.isEmpty || password.isEmpty) {
        IToast.showTop(appLocalizations.emailOrPasswordCannotBeEmpty);
        return;
      }
      var resPower = await LoginApi.getMailPower(mail);
      if (resPower['ret'] == "201") {
        mailPower = resPower['pVInfo'];
      } else {
        IToast.showTop(appLocalizations.emailNotExist);
        return;
      }
      var resGt = await LoginApi.loginByMailGt(mail);
      if (resGt['ret'] == "201") {
        String tk = resGt['tk'];
        var resL = await LoginApi.loginByMailL(mail, password, tk);
        if (resL['ret'] == "200") {
          IToast.showTop(appLocalizations.loginSuccess);
          appProvider.token = resL['token'] ?? "";
          await RequestUtil.clearCookie();
          await ChewieHiveUtil.put(HiveUtil.userIdKey, resL['userId']);
          await ChewieHiveUtil.put(HiveUtil.tokenKey, resL['token']);
          await ChewieHiveUtil.put(
              HiveUtil.tokenTypeKey, TokenType.lofterID.index);
          mainScreenState?.login();
        } else if (resL['ret'] == "413" && resL['dt'] == "01") {
          IToast.showTop(appLocalizations.retryLoginLater);
        } else if (resL['ret'] == "413" && resL['dt'] == "02") {
          IToast.showTop(appLocalizations.retryLoginTomorrow);
        } else if (resL['ret'] == "413" && resL['dt'] == "02") {
          IToast.showTop(appLocalizations.retryLoginLaterWithIP);
        } else if (resL['ret'] == "413") {
          IToast.showTop(appLocalizations.accountOrPasswordWrong);
        } else if (resL['ret'] == "447") {
          IToast.showTop(appLocalizations.retryLaterWithFrequency);
        } else {
          IToast.showTop(appLocalizations.passwordWrong);
        }
      } else {
        IToast.showTop(appLocalizations.loadUnkownError);
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
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ResponsiveAppBar(
          title: appLocalizations.loginByEmail,
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
                      hint: appLocalizations.inputEmail,
                      textInputAction: TextInputAction.next,
                      controller: _mailController,
                      focusNode: _mailFocusNode,
                      autofillHints: const [AutofillHints.email],
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: Icons.mail_outline_rounded,
                      ),
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.clear,
                      ),
                    ),
                    LoginInputItem(
                      hint: appLocalizations.inputPassword,
                      textInputAction: TextInputAction.done,
                      focusNode: _passwordFocusNode,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _login(),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: Icons.verified_outlined,
                      ),
                      controller: _passwordController,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.password,
                      ),
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
                            icon: Icons.phone_android_rounded,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                const LoginByCaptchaScreen(),
                              );
                            }),
                        const SizedBox(width: 30),
                        ToolButton(
                            context: context,
                            icon: Icons.password_rounded,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByPasswordScreen(
                                  initPassword: _passwordController.text,
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
