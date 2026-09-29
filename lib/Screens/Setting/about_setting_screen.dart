import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Screens/Setting/egg_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../Utils/cloud_control_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

const countThreholdLevel1 = 3;
const countThreholdLevel2 = 6;
const countThreholdLevel3 = 12;
const countThreholdLevel4 = 18;
const countThreholdLevel5 = 24;

class AboutSettingScreen extends BaseSettingScreen {
  const AboutSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/about";

  @override
  State<AboutSettingScreen> createState() => _AboutSettingScreenState();
}

class _AboutSettingScreenState extends BaseDynamicState<AboutSettingScreen>
    with TickerProviderStateMixin {
  int count = 0;
  late String appName = "";
  bool inAppBrowser = ChewieHiveUtil.getBool(HiveUtil.inappWebviewKey);

  Timer? _timer;
  Timer? _hapticTimer;
  final ShakeAnimationController _shakeAnimationController =
      ShakeAnimationController();

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
      });
    });
  }

  void diaplayCelebrate() {
    restore();
    RouteUtil.pushFadeRoute(context, const EggScreen());
    setState(() {});
  }

  void restore() {
    count = 0;
    if (_timer != null) _timer!.cancel();
    if (_hapticTimer != null) _hapticTimer!.cancel();
    if (_shakeAnimationController.animationRuning) {
      _shakeAnimationController.stop();
    }
    setState(() {});
  }

  void startShake() {
    _shakeAnimationController.start(shakeCount: 0);
  }

  void setHapticTimer(VoidCallback callback) {
    if (_hapticTimer != null) _hapticTimer!.cancel();
    _hapticTimer =
        Timer.periodic(const Duration(milliseconds: 80), (_) => callback());
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.about,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      overrideBody: EasyRefresh(
        child: ListView(
          padding: widget.padding,
          children: [
            const SizedBox(height: 10),
            Center(
              child: ClickableWrapper(
                child: GestureDetector(
                  onLongPressStart: (details) {
                    if (controlProvider.globalControl.enableEasterEggs) {
                      if (_timer != null) _timer!.cancel();
                      _timer =
                          Timer.periodic(const Duration(seconds: 1), (timer) {
                        count = timer.tick;
                        if (count >= countThreholdLevel4 / 4) {
                          diaplayCelebrate();
                        } else if (count >= countThreholdLevel3 / 4) {
                          setHapticTimer(HapticFeedback.heavyImpact);
                        } else if (count >= countThreholdLevel2 / 4) {
                          setHapticTimer(HapticFeedback.mediumImpact);
                        } else if (count >= countThreholdLevel1 / 4) {
                          startShake();
                          setHapticTimer(HapticFeedback.lightImpact);
                        }
                        setState(() {});
                      });
                    }
                  },
                  onLongPressEnd: (details) {
                    restore();
                  },
                  child: ShakeAnimationWidget(
                    shakeAnimationController: _shakeAnimationController,
                    shakeAnimationType: ShakeAnimationType.RandomShake,
                    isForward: false,
                    shakeRange: 0.1,
                    child: Hero(
                      tag: "logo-egg",
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              alignment: Alignment.center,
              child: Text(
                appName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.zero,
              child: ScrollConfiguration(
                  behavior: NoShadowScrollBehavior(),
                  child: Consumer<LoftifyControlProvider>(
                    builder: (context, cloudControlProvider, _) => ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        CaptionItem(
                          context: context,
                          title: appName,
                          children: [
                            EntryItem(
                              title: appLocalizations.changelog,
                              showLeading: true,
                              onTap: () {
                                RouteUtil.pushPanelCupertinoRoute(
                                    context, const UpdateLogScreen());
                              },
                              leading: LoftifyIcons.merge,
                            ),
                            EntryItem(
                              title: appLocalizations.bugReport,
                              onTap: () {
                                UriUtil.launchUrlUri(
                                  context,
                                  cloudControlProvider.globalControl.issueUrl,
                                );
                              },
                              showLeading: true,
                              leading: LoftifyIcons.bug,
                              trailing: LoftifyIcons.openExternal,
                            ),
                            EntryItem(
                              title: appLocalizations.githubRepo,
                              onTap: () {
                                UriUtil.launchUrlUri(
                                  context,
                                  cloudControlProvider.globalControl.repoUrl,
                                );
                              },
                              showLeading: true,
                              leading: LoftifyIcons.commit,
                              trailing: LoftifyIcons.openExternal,
                            ),
                          ],
                        ),
                        CaptionItem(
                          context: context,
                          title: appLocalizations.contact,
                          children: [
                            EntryItem(
                              title: appLocalizations.rate,
                              showLeading: true,
                              onTap: () {
                                BottomSheetBuilder.showBottomSheet(
                                  context,
                                  (context) => const StarBottomSheet(),
                                  responsive: true,
                                );
                              },
                              leading: LoftifyIcons.review,
                            ),
                            EntryItem(
                              title: appLocalizations.shareApp,
                              showLeading: true,
                              onTap: () {
                                Share.share(
                                  cloudControlProvider.globalControl.shareText,
                                );
                              },
                              leading: LoftifyIcons.share,
                            ),
                            EntryItem(
                              title: appLocalizations.contact,
                              onTap: () {
                                UriUtil.launchEmailUri(
                                  context,
                                  cloudControlProvider
                                      .globalControl.feedbackEmail,
                                  subject: cloudControlProvider
                                      .globalControl.feedbackSubject,
                                  body: cloudControlProvider
                                      .globalControl.feedbackBody,
                                );
                              },
                              showLeading: true,
                              leading: LoftifyIcons.support,
                              trailing: LoftifyIcons.contact,
                            ),
                            EntryItem(
                              title: appLocalizations.officialWebsite,
                              onTap: () {
                                UriUtil.launchUrlUri(
                                  context,
                                  cloudControlProvider
                                      .globalControl.officialWebsite,
                                );
                              },
                              showLeading: true,
                              leading: LoftifyIcons.language,
                              trailing: LoftifyIcons.openExternal,
                            ),
                            if (cloudControlProvider.globalControl.showQQGroup)
                              EntryItem(
                                title: appLocalizations.qqGroup,
                                onTap: () {
                                  UriUtil.openExternal(cloudControlProvider
                                      .globalControl.qqGroupUrl);
                                },
                                showLeading: true,
                                leading: LoftifyIcons.group,
                                trailing: LoftifyIcons.openExternal,
                              ),
                            if (cloudControlProvider
                                .globalControl.showTelegramGroup)
                              EntryItem(
                                title: appLocalizations.telegramGroup,
                                onTap: () {
                                  UriUtil.openExternal(cloudControlProvider
                                      .globalControl.telegramGroupUrl);
                                },
                                showLeading: true,
                                leading: LoftifyIcons.send,
                                trailing: LoftifyIcons.openExternal,
                              ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
