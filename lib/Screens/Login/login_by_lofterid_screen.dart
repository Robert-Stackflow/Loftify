import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/login_api.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/login_lofterid_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/request_util.dart';
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/login_input_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class LoginByLofterIDScreen extends StatefulWidget {
  const LoginByLofterIDScreen({super.key, this.initPassword});

  static const String routeName = "/login/lofterID";

  final String? initPassword;

  @override
  State<LoginByLofterIDScreen> createState() => _LoginByLofterIDScreenState();
}

class _LoginByLofterIDScreenState
    extends BaseDynamicState<LoginByLofterIDScreen>
    with TickerProviderStateMixin {
  late TextEditingController _lofterIDController;
  late TextEditingController _passwordController;
  final FocusNode _lofterIDFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _lofterIDController = TextEditingController();
    _passwordController = TextEditingController();
    _lofterIDController.text = defaultLofterID;
    _passwordController.text = widget.initPassword ?? defaultPassword;
  }

  @override
  void dispose() {
    _lofterIDController.dispose();
    _passwordController.dispose();
    _lofterIDFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    FocusManager.instance.primaryFocus?.unfocus();
    String lofterID = _lofterIDController.text;
    String password = _passwordController.text;
    if (lofterID.isEmpty || password.isEmpty) {
      IToast.showTop(appLocalizations.lofterIDOrPasswordCannotBeEmpty);
      return;
    }
    LoginApi.loginByLofterID(lofterID, password).then((value) async {
      try {
        LoginLofterIDResponse loginResponse =
            LoginLofterIDResponse.fromJson(value);
        if (loginResponse.status != 200) {
          IToast.showTop(loginResponse.desc);
        } else {
          IToast.showTop(appLocalizations.loginSuccess);
          appProvider.token = loginResponse.token ?? "";
          await RequestUtil.clearCookie();
          await ChewieHiveUtil.put(HiveUtil.userIdKey, loginResponse.userId);
          await ChewieHiveUtil.put(HiveUtil.tokenKey, loginResponse.token);
          await ChewieHiveUtil.put(
              HiveUtil.tokenTypeKey, TokenType.lofterID.index);
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
          title: appLocalizations.loginByLofterID,
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
                      hint: appLocalizations.inputLofterID,
                      textInputAction: TextInputAction.next,
                      controller: _lofterIDController,
                      focusNode: _lofterIDFocusNode,
                      autofillHints: const [AutofillHints.username],
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      leadingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.icon,
                        icon: LoftifyIcons.lofterId,
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
                        icon: LoftifyIcons.password,
                      ),
                      controller: _passwordController,
                      tailingConfig: InputItemLeadingTailingConfig(
                        type: InputItemLeadingTailingType.password,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: LoftifyButton(
                        label: appLocalizations.login,
                        onPressed: _login,
                        size: LoftifyButtonSize.large,
                        expand: true,
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
                                const LoginByCaptchaScreen(),
                              );
                            }),
                        const SizedBox(width: 30),
                        ToolButton(
                            context: context,
                            icon: LoftifyIcons.password,
                            onPressed: () {
                              RouteUtil.pushCupertinoRoute(
                                context,
                                LoginByPasswordScreen(
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
