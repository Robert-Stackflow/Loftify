import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Providers/global_provider.dart';
import 'package:loftify/Screens/Info/favorite_folder_list_screen.dart';
import 'package:loftify/Screens/Info/history_screen.dart';
import 'package:loftify/Screens/Info/share_screen.dart';
import 'package:loftify/Screens/Lock/pin_change_screen.dart';
import 'package:loftify/Screens/Login/login_by_captcha_screen.dart';
import 'package:loftify/Screens/Login/login_by_lofterid_screen.dart';
import 'package:loftify/Screens/Login/login_by_password_screen.dart';
import 'package:loftify/Screens/Navigation/mine_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Screens/Setting/apperance_setting_screen.dart';
import 'package:loftify/Screens/Setting/blacklist_setting_screen.dart';
import 'package:loftify/Screens/Setting/experiment_setting_screen.dart';
import 'package:loftify/Screens/Setting/general_setting_screen.dart';
import 'package:loftify/Screens/Setting/image_setting_screen.dart';
import 'package:loftify/Screens/Setting/lofter_basic_setting_screen.dart';
import 'package:loftify/Screens/Setting/navitem_setting_screen.dart';
import 'package:loftify/Screens/Setting/operation_setting_screen.dart';
import 'package:loftify/Screens/Setting/select_theme_screen.dart';
import 'package:loftify/Screens/Setting/setting_screen.dart';
import 'package:loftify/Screens/Setting/tagshield_setting_screen.dart';
import 'package:loftify/Screens/Setting/userdynamicshield_setting_screen.dart';
import 'package:loftify/Utils/fontsize_util.dart';
import 'package:loftify/Utils/request_header_util.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'Providers/provider_manager.dart';
import 'Screens/Info/favorite_folder_detail_screen.dart';
import 'Screens/Info/like_screen.dart';
import 'Screens/Info/user_detail_screen.dart';
import 'Screens/Lock/pin_verify_screen.dart';
import 'Screens/Navigation/dynamic_screen.dart';
import 'Screens/Navigation/home_screen.dart';
import 'Screens/Setting/about_setting_screen.dart';
import 'Screens/main_screen.dart';
import 'Utils/notification_util.dart';
import 'Utils/utils.dart';
import 'Widgets/Custom/restart_widget.dart';
import 'generated/l10n.dart';

Future<void> main(List<String> args) async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await ProviderManager.init();
  NotificationUtil.init();
  if (Utils.isMobile()) {
    await initDisplayMode();
    if (Utils.isAndroid()) {
      await RequestHeaderUtil.initAndroidInfo();
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  if (Utils.isDesktop()) {
    await initWindow();
    initTray();
  }
  runApp(const RestartWidget(child: MyApp()));
  FlutterNativeSplash.remove();
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1120, 740),
    minimumSize: Size(450, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

Future<void> initTray() async {
  await trayManager.setIcon(
    Platform.isWindows
        ? 'assets/logo-transparent-big.ico'
        : 'assets/logo-transparent-big.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: '显示 Loftify',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'show_official_website',
        label: '官网',
      ),
      MenuItem(
        key: 'show_github_repo',
        label: 'GitHub',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '退出 Loftify',
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

Future<void> initDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  await FlutterDisplayMode.setPreferredMode(await FlutterDisplayMode.preferred);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ProviderManager.globalProvider),
      ],
      child: Consumer<GlobalProvider>(
        builder: (context, globalProvider, child) => MaterialApp(
          restorationScopeId: "Loftify",
          navigatorKey: ProviderManager.globalNavigatorKey,
          title: 'Loftify',
          theme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.light
              ? globalProvider.lightTheme
              : globalProvider.darkTheme,
          darkTheme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.dark
              ? globalProvider.darkTheme
              : globalProvider.lightTheme,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: globalProvider.locale,
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) {
            if (globalProvider.locale != null) {
              return globalProvider.locale;
            } else if (locale != null && supportedLocales.contains(locale)) {
              return locale;
            } else {
              try {
                return Localizations.localeOf(context);
              } catch (_) {
                return const Locale("en", "US");
              }
            }
          },
          home: const MainScreen(),
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  FontSizeUtil.getTextFactor(globalProvider.fontSize),
                ),
              ),
              child: widget!,
            );
          },
          routes: {
            HomeScreen.routeName: (context) => const HomeScreen(),
            MineScreen.routeName: (context) => const MineScreen(),
            DynamicScreen.routeName: (context) => const DynamicScreen(),
            PostDetailScreen.routeName: (context) => PostDetailScreen(
                  postItem: ModalRoute.of(context)!.settings.arguments
                      as PostListItem,
                  isArticle: false,
                ),
            SettingScreen.routeName: (context) => const SettingScreen(),
            HistoryScreen.routeName: (context) => const HistoryScreen(),
            LikeScreen.routeName: (context) => LikeScreen(),
            ShareScreen.routeName: (context) => ShareScreen(),
            UserDetailScreen.routeName: (context) =>
                const UserDetailScreen(blogId: 0, blogName: ''),
            FavoriteFolderListScreen.routeName: (context) =>
                const FavoriteFolderListScreen(),
            FavoriteFolderDetailScreen.routeName: (context) =>
                FavoriteFolderDetailScreen(
                    favoriteFolderId:
                        ModalRoute.of(context)!.settings.arguments as int),
            AboutSettingScreen.routeName: (context) =>
                const AboutSettingScreen(),
            NavItemSettingScreen.routeName: (context) =>
                const NavItemSettingScreen(),
            SelectThemeScreen.routeName: (context) => const SelectThemeScreen(),
            OperationSettingScreen.routeName: (context) =>
                const OperationSettingScreen(),
            AppearanceSettingScreen.routeName: (context) =>
                const AppearanceSettingScreen(),
            GeneralSettingScreen.routeName: (context) =>
                const GeneralSettingScreen(),
            ImageSettingScreen.routeName: (context) =>
                const ImageSettingScreen(),
            ExperimentSettingScreen.routeName: (context) =>
                const ExperimentSettingScreen(),
            PinChangeScreen.routeName: (context) => const PinChangeScreen(),
            LofterBasicSettingScreen.routeName: (context) =>
                const LofterBasicSettingScreen(),
            BlacklistSettingScreen.routeName: (context) =>
                const BlacklistSettingScreen(),
            TagShieldSettingScreen.routeName: (context) =>
                const TagShieldSettingScreen(),
            UserDynamicShieldSettingScreen.routeName: (context) =>
                const UserDynamicShieldSettingScreen(),
            PinVerifyScreen.routeName: (context) => PinVerifyScreen(
                  onSuccess:
                      ModalRoute.of(context)!.settings.arguments as Function(),
                ),
            LoginByPasswordScreen.routeName: (context) =>
                const LoginByPasswordScreen(),
            LoginByCaptchaScreen.routeName: (context) =>
                const LoginByCaptchaScreen(),
            LoginByLofterIDScreen.routeName: (context) =>
                const LoginByLofterIDScreen(),
          },
        ),
      ),
    );
  }
}
