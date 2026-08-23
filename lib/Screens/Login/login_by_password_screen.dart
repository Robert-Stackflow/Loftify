import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Models/login_response.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_lofterid_screen.dart';
import 'package:loftify/Utils/constant.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/request_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/login_input_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class LoginByPasswordScreen extends StatefulWidget {
  const LoginByPasswordScreen({super.key, this.initPhone, this.initPassword});

  static const String routeName = "/login/password";

  final String? initPhone;
  final String? initPassword;

  @override
  State<LoginByPasswordScreen> createState() => _LoginByPasswordScreenState();
}

class _LoginByPasswordScreenState
    extends BaseDynamicState<LoginByPasswordScreen>
    with TickerProviderStateMixin {
  late TextEditingController _mobileController;
  late TextEditingController _passwordController;
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _passwordController = TextEditingController();
    _mobileController.text = widget.initPhone ?? defaultPhone;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    String mobile = _mobileController.text;
    String password = _passwordController.text;
    if (mobile.isEmpty || password.isEmpty) {
      IToast.showTop(appLocalizations.phoneOrPasswordCannotBeEmpty);
      return;
    }
    LoginApi.loginByPassword(mobile, password).then((value) async {
      try {
        LoginResponse loginResponse = LoginResponse.fromJson(value);
        if (loginResponse.result != 0) {
          IToast.showTop(loginResponse.desc);
        } else {
          IToast.showTop(appLocalizations.loginSuccess);
          appProvider.token = loginResponse.token ?? "";
          await RequestUtil.clearCookie();
          await ChewieHiveUtil.put(HiveUtil.userIdKey, loginResponse.userid);
          await ChewieHiveUtil.put(HiveUtil.tokenKey, loginResponse.token);
          await ChewieHiveUtil.put(
              HiveUtil.deviceIdKey, loginResponse.deviceid);
          await ChewieHiveUtil.put(
              HiveUtil.tokenTypeKey, TokenType.password.index);
          mainScreenState?.login();
        }
      } catch (e, t) {
        ILogger.error("Failed to login by LofterID", e, t);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ResponsiveAppBar(
          title: appLocalizations.loginByPassword,
          showBack: !ResponsiveUtil.isLandscapeLayout(),
          leadingIcon: LoftifyIcons.close,
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
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: LoftifyIcons.phone,
                      ),
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.clear,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    LoginInputItem(
                      hint: appLocalizations.inputPassword,
                      textInputAction: TextInputAction.done,
                      focusNode: _passwordFocusNode,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _login(),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: LoftifyIcons.password,
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
                        background: Theme.of(context).primaryColor,
                        onPressed: _login,
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
                            icon: LoftifyIcons.phone,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByCaptchaScreen(
                                    initPhone: _mobileController.text),
                              );
                            }),
                        const SizedBox(width: 30),
                        ToolButton(
                            context: context,
                            icon: LoftifyIcons.lofterId,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByLofterIDScreen(
                                  initPassword: _passwordController.text,
                                ),
                              );
                            }),
                        // const SizedBox(width: 30),
                        // ToolButton(
                        //     context: context,
                        //     icon: LoftifyIcons.email,
                        //     onTap: () {
                        //       RouteUtil.pushCupertinoRoute(
                        //         context,
                        //         LoginByMailScreen(
                        //           initPassword: _passwordController.text,
                        //         ),
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
