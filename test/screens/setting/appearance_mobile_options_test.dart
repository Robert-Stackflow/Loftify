import 'dart:io';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:loftify/Screens/Setting/apperance_setting_screen.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    final directory =
        await Directory.systemTemp.createTemp('appearance_mobile_');
    Hive.init(directory.path);
    await Hive.openBox(ChewieHiveUtil.settingsBox);
    appProvider.hideHomeAppBarOnScroll = true;
    appProvider.hideSearchNavigation = true;
    await Hive.box(ChewieHiveUtil.settingsBox).flush();
  });

  testWidgets('desktop hides mobile home options without clearing preferences',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: appProvider,
      child: MaterialApp(
        locale: const Locale('en'),
        theme: ChewieThemeColorData.defaultLightThemes.first.toThemeData(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ChewieLocalizations.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        home: Builder(builder: (context) {
          chewieProvider.setRootContext(context);
          return const AppearanceSettingScreen();
        }),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));

    final context = tester.element(find.byType(AppearanceSettingScreen));
    final strings = AppLocalizations.of(context)!;
    final home = tester.widget<CaptionItem>(find.byWidgetPredicate(
      (widget) => widget is CaptionItem && widget.title == strings.home,
    ));
    expect(home.children, hasLength(2));
    expect((home.children.first as CheckboxItem).title,
        strings.showArticleInRecommendFlow);
    expect((home.children.last as CheckboxItem).title,
        strings.showVideoInRecommendFlow);
    expect(find.text(strings.hideHomeAppBarOnScroll), findsNothing);
    expect(find.text(strings.hideSearchNavigation), findsNothing);
    expect(appProvider.hideHomeAppBarOnScroll, isTrue);
    expect(appProvider.hideSearchNavigation, isTrue);
    expect(ChewieHiveUtil.getBool(HiveUtil.hideHomeAppBarOnScrollKey), isTrue);
    expect(ChewieHiveUtil.getBool(HiveUtil.hideSearchNavigationKey), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
