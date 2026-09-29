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
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/Item/login_input_item.dart';
import '../../Widgets/Login/loftify_login_layout.dart';
import '../../Widgets/loftify_icons.dart';
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
          leadingIcon: LoftifyIcons.close,
          onTapBack: () => Navigator.maybeOf(context)?.maybePop(),
          showBorder: false,
          titleLeftMargin: ResponsiveUtil.isLandscapeLayout() ? 15 : 5,
        ),
        body: LoftifyLoginLayout(
          formChildren: [
            LoginInputItem(
              hint: appLocalizations.inputEmail,
              textInputAction: TextInputAction.next,
              controller: _mailController,
              focusNode: _mailFocusNode,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              leadingConfig: InputItemLeadingTailingConfig(
                type: InputItemLeadingTailingType.icon,
                icon: LoftifyIcons.email,
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
          ],
          primaryAction: LoftifyButton(
            label: appLocalizations.login,
            onPressed: _login,
            size: LoftifyButtonSize.large,
            expand: true,
          ),
          alternativeTitle: appLocalizations.otherLoginMethods,
          alternativeMethods: [
            LoftifyLoginMethod(
              label: appLocalizations.loginByCaptcha,
              icon: LoftifyIcons.phone,
              onPressed: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  const LoginByCaptchaScreen(),
                );
              },
            ),
            LoftifyLoginMethod(
              label: appLocalizations.loginByPassword,
              icon: LoftifyIcons.password,
              onPressed: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  LoginByPasswordScreen(
                    initPassword: _passwordController.text,
                  ),
                );
              },
            ),
            LoftifyLoginMethod(
              label: appLocalizations.loginByLofterID,
              icon: LoftifyIcons.lofterId,
              onPressed: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  LoginByLofterIDScreen(
                    initPassword: _passwordController.text,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
