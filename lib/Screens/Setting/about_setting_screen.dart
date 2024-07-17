import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/update_log_screen.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:loftify/Widgets/BottomSheet/star_bottom_sheet.dart';
import 'package:loftify/Widgets/Custom/no_shadow_scroll_behavior.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class AboutSettingScreen extends StatefulWidget {
  const AboutSettingScreen({super.key});

  static const String routeName = "/setting/about";

  @override
  State<AboutSettingScreen> createState() => _AboutSettingScreenState();
}

class _AboutSettingScreenState extends State<AboutSettingScreen>
    with TickerProviderStateMixin {
  int count = 0;
  late String appName = "";
  bool inAppBrowser = HiveUtil.getBool(key: HiveUtil.inappWebviewKey);
  String releaseUrl = "https://github.com/Robert-Stackflow/Loftify/releases";
  String issueUrl = "https://github.com/Robert-Stackflow/Loftify/issues";
  String repoUrl = "https://github.com/Robert-Stackflow/Loftify";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveUtil.isDesktop()
          ? null
          : ItemBuilder.buildSimpleAppBar(
              transparent: true,
              leading: Icons.close_rounded,
              context: context,
            ),
      body: EasyRefresh(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
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
              margin: const EdgeInsets.all(10),
              child: ScrollConfiguration(
                behavior: NoShadowScrollBehavior(),
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 10),
                    // ItemBuilder.buildEntryItem(
                    //   context: context,
                    //   title: S.current.contributor,
                    //   topRadius: true,
                    //   showLeading: true,
                    //   onTap: () {
                    //     UriUtil.launchUrlUri(
                    //         "https://apps.cloudchewie.com/loftify/contributor");
                    //   },
                    //   leading: Icons.supervised_user_circle_outlined,
                    // ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.changeLog,
                      topRadius: true,
                      showLeading: true,
                      onTap: () {
                        // UriUtil.launchUrlUri(context, releaseUrl);
                        RouteUtil.pushCupertinoRoute(
                            context, const UpdateLogScreen());
                      },
                      leading: Icons.merge_type_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.bugReport,
                      onTap: () {
                        UriUtil.launchUrlUri(context, issueUrl);
                      },
                      showLeading: true,
                      leading: Icons.bug_report_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.githubRepo,
                      onTap: () {
                        UriUtil.launchUrlUri(context, repoUrl);
                      },
                      showLeading: true,
                      bottomRadius: true,
                      leading: Icons.commit_outlined,
                    ),
                    const SizedBox(height: 10),
                    ItemBuilder.buildEntryItem(
                      topRadius: true,
                      context: context,
                      title: S.current.rate,
                      showLeading: true,
                      onTap: () {
                        BottomSheetBuilder.showBottomSheet(
                          context,
                          (context) => const StarBottomSheet(),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        );
                      },
                      leading: Icons.rate_review_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.shareApp,
                      showLeading: true,
                      onTap: () {
                        Share.share(
                            "Loftify - 简洁的LOFTER第三方APP\nhttps://apps.cloudchewie.com/loftify");
                      },
                      leading: Icons.share_rounded,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.contact,
                      onTap: () {
                        UriUtil.launchEmailUri(
                          context,
                          "2014027378@qq.com",
                          subject: "反馈",
                          body: "",
                        );
                      },
                      showLeading: true,
                      leading: Icons.contact_support_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.officialWebsite,
                      onTap: () {
                        UriUtil.launchUrlUri(
                            context, "https://apps.cloudchewie.com/loftify");
                      },
                      showLeading: true,
                      leading: Icons.language_outlined,
                    ),
                    ItemBuilder.buildEntryItem(
                      context: context,
                      title: S.current.telegramGroup,
                      onTap: () {
                        UriUtil.openExternal("https://t.me/Loftify");
                      },
                      bottomRadius: true,
                      showLeading: true,
                      leading: Icons.telegram_outlined,
                    ),
                    const SizedBox(height: 10)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
