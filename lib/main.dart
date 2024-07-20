import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:loftify/Database/database_manager.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Utils/app_provider.dart';
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
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/fontsize_util.dart';
import 'package:loftify/Utils/request_header_util.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'Screens/Info/favorite_folder_detail_screen.dart';
import 'Screens/Info/like_screen.dart';
import 'Screens/Info/user_detail_screen.dart';
import 'Screens/Lock/pin_verify_screen.dart';
import 'Screens/Navigation/dynamic_screen.dart';
import 'Screens/Navigation/home_screen.dart';
import 'Screens/Setting/about_setting_screen.dart';
import 'Screens/main_screen.dart';
import 'Utils/enums.dart';
import 'Utils/notification_util.dart';
import 'Utils/responsive_util.dart';
import 'generated/l10n.dart';

int? kWindowId;
MultiWindowType? kWindowType;
late List<String> kBootArgs;

Future<void> main(List<String> args) async {
  runMyApp(args);
}

Future<void> runMyApp(List<String> args) async {
  if (args.isNotEmpty && args.first == 'multi_window') {
    await initApp();
    kWindowId = int.parse(args[1]);
    WindowController.fromWindowId(kWindowId!).showTitleBar(true);
    final argument = args[2].isEmpty
        ? <String, dynamic>{}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    int type = argument['type'] ?? -1;
    argument['windowId'] = kWindowId;
    kWindowType = type.windowType;
    runMultiWindow(argument, kWindowType!);
  } else {
    await initApp();
    if (ResponsiveUtil.isMobile()) {
      await initDisplayMode();
      if (ResponsiveUtil.isAndroid()) {
        await RequestHeaderUtil.initAndroidInfo();
        SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
      }
    }
    if (ResponsiveUtil.isDesktop()) {
      await initWindow();
      initTray();
    }
    runApp(const MyApp());
    FlutterNativeSplash.remove();
  }
}

Future<void> initApp() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await HotKeyManager.instance.unregisterAll();
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DatabaseManager.getDataBase();
  Hive.defaultDirectory = await FileUtil.getApplicationDir();
  NotificationUtil.init();
  FlutterError.onError = (FlutterErrorDetails details) async {
    File errorFile = File("${await FileUtil.getApplicationDir()}/error.log");
    if (!errorFile.existsSync()) {
      errorFile.createSync();
    }
    errorFile
        .writeAsStringSync(errorFile.readAsStringSync() + details.toString());
    if (details.stack != null) {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1120, 740),
    minimumSize: Size(670, 520),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
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

void runMultiWindow(
  Map<String, dynamic> argument,
  MultiWindowType appType,
) async {
  late String title;
  late Widget widget;
  switch (appType) {
    case MultiWindowType.Main:
      title = "Loftify";
      widget = const MainScreen();
      break;
    case MultiWindowType.Setting:
      title = "设置 - Loftify";
      widget = const SettingScreen();
      break;
    default:
      break;
  }
  runApp(MyApp(title: title, home: widget));
  WindowController.fromWindowId(kWindowId!).show();
}

Future<void> initDisplayMode() async {
  await FlutterDisplayMode.setHighRefreshRate();
  await FlutterDisplayMode.setPreferredMode(await FlutterDisplayMode.preferred);
}

class MyApp extends StatelessWidget {
  final Widget home;
  final String title;

  const MyApp(
      {super.key, this.home = const MainScreen(), this.title = 'Loftify'});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, globalProvider, child) => MaterialApp(
          navigatorKey: globalNavigatorKey,
          title: title,
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
          home: home,
          builder: (context, widget) {
            return Overlay(
              initialEntries: [
                if (widget != null) ...[
                  OverlayEntry(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          FontSizeUtil.getTextFactor(globalProvider.fontSize),
                        ),
                      ),
                      child: widget,
                    ),
                  ),
                ],
              ],
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
