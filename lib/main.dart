import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive/hive.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:loftify/Database/database_manager.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/request_header_util.dart';
import 'package:loftify/Utils/request_util.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'Screens/main_screen.dart';
import 'Utils/constant.dart';
import 'Utils/ilogger.dart';
import 'Utils/notification_util.dart';
import 'Utils/responsive_util.dart';
import 'Widgets/Item/item_builder.dart';
import 'generated/l10n.dart';

const List<String> kWindowsSchemes = ["lofter"];

Future<void> main(List<String> args) async {
  runMyApp(args);
}

Future<void> runMyApp(List<String> args) async {
  await initApp();
  if (ResponsiveUtil.isAndroid()) {
    await initDisplayMode();
    await RequestHeaderUtil.initAndroidInfo();
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
  if (ResponsiveUtil.isDesktop()) {
    await initWindow();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
    await launchAtStartup.enable();
    await launchAtStartup.disable();
    await LocalNotifier.instance.setup(
      appName: packageInfo.appName,
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    HiveUtil.put(HiveUtil.launchAtStartupKey,
        await LaunchAtStartup.instance.isEnabled());
    for (String scheme in kWindowsSchemes) {
      await protocolHandler.register(scheme);
    }
    await HotKeyManager.instance.unregisterAll();
  }
  runApp(MyApp(home: MainScreen(key: mainScreenKey)));
  FlutterNativeSplash.remove();
}

Future<void> initApp() async {
  FlutterError.onError = onError;
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024 * 2;
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await DatabaseManager.getDataBase();
  Hive.defaultDirectory = await FileUtil.getApplicationDir();
  NotificationUtil.init();
  await ResponsiveUtil.init();
  await RequestUtil.init();
}

Future<void> initWindow() async {
  await windowManager.ensureInitialized();
  Offset position = HiveUtil.getWindowPosition();
  WindowOptions windowOptions = WindowOptions(
    size: HiveUtil.getWindowSize(),
    minimumSize: minimumSize,
    center: position == Offset.zero,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    if (position != Offset.zero) await windowManager.setPosition(position);
  });
}

Future<void> initDisplayMode() async {
  try {
    var modes = await FlutterDisplayMode.supported;
    ILogger.info("Supported display modes: $modes");
    ILogger.info(
        "Current active display mode: ${await FlutterDisplayMode.active}\nCurrent preferred display mode: ${await FlutterDisplayMode.preferred}");
    int refreshRate =
        HiveUtil.getInt(HiveUtil.refreshRateKey, defaultValue: -1);
    if (refreshRate == -1) {
      await FlutterDisplayMode.setHighRefreshRate();
      ILogger.info("Config display mode: high refresh rate");
    } else {
      DisplayMode configMode = modes[refreshRate.clamp(0, modes.length - 1)];
      await FlutterDisplayMode.setPreferredMode(configMode);
      ILogger.info("Config display mode: ${configMode.toString()}");
    }
    ILogger.info(
        "Current active display mode after config: ${await FlutterDisplayMode.active}\nCurrent preferred display mode after config: ${await FlutterDisplayMode.preferred}");
  } catch (e, t) {
    ILogger.error("Failed to init display mode", e, t);
  }
}

Future<void> onError(FlutterErrorDetails details) async {
  try {
    File errorFile = File(join(await FileUtil.getLogDir(), "error.log"));
    if (!errorFile.existsSync()) errorFile.createSync();
    errorFile.writeAsStringSync(
        "${details.exceptionAsString()}\n${details.stack}",
        mode: FileMode.append);
    if (details.stack != null) {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  } catch (e, t) {
    ILogger.error("Failed to write error log", e, t);
  }
}

class MyApp extends StatelessWidget {
  final Widget home;
  final String title;

  const MyApp({
    super.key,
    required this.home,
    this.title = 'Loftify',
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: controlProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, globalProvider, child) => MaterialApp(
          navigatorKey: globalNavigatorKey,
          navigatorObservers: [routeObserver],
          title: title,
          theme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.light
              ? globalProvider.lightTheme.toThemeData()
              : globalProvider.darkTheme.toThemeData(),
          darkTheme: globalProvider.getBrightness() == null ||
                  globalProvider.getBrightness() == Brightness.dark
              ? globalProvider.darkTheme.toThemeData()
              : globalProvider.lightTheme.toThemeData(),
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
              } catch (e, t) {
                ILogger.error("Failed to load locale", e, t);
                return const Locale("en", "US");
              }
            }
          },
          home: ItemBuilder.buildContextMenuOverlay(home),
          builder: (context, widget) {
            return Overlay(
              initialEntries: [
                if (widget != null) ...[
                  OverlayEntry(
                    builder: (context) => Listener(
                      onPointerDown: (_) {
                        if (!ResponsiveUtil.isDesktop() &&
                            searchScreenState?.hasSearchFocus == true) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      child: widget,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
