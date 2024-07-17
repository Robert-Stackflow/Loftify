import 'package:flutter/material.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../Api/github_api.dart';
import '../../Models/github_response.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class UpdateLogScreen extends StatefulWidget {
  const UpdateLogScreen({super.key});

  static const String routeName = "/setting/updateLog";

  @override
  State<UpdateLogScreen> createState() => _UpdateLogScreenState();
}

class _UpdateLogScreenState extends State<UpdateLogScreen>
    with TickerProviderStateMixin {
  String releaseUrl = "https://github.com/Robert-Stackflow/Loftify/releases";
  List<ReleaseItem> releaseItems = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  String currentVersion = "";
  String latestVersion = "";

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
  }

  Future<void> fetchReleases() async {
    await GithubApi.getReleases("Robert-Stackflow", "Loftify")
        .then((releases) async {
      for (var release in releases) {
        String tagName = release.tagName;
        tagName = tagName.replaceAll(RegExp(r'[a-zA-Z]'), '');
        setState(() {
          if (latestVersion.compareTo(tagName) < 0) {
            latestVersion = tagName;
          }
        });
      }
      setState(() {
        releaseItems = releases;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItemBuilder.buildSimpleAppBar(
        transparent: true,
        title: S.current.changeLog,
        leading: Icons.arrow_back_rounded,
        context: context,
      ),
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          await fetchReleases();
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemBuilder: (context, index) => _buildItem(releaseItems[index]),
          itemCount: releaseItems.length,
        ),
      ),
    );
  }

  _buildItem(ReleaseItem item) {
    return GestureDetector(
      onTap: () {
        UriUtil.launchUrlUri(context, item.htmlUrl);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ItemBuilder.buildContainerItem(
          topRadius: true,
          bottomRadius: true,
          context: context,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 2),
                    Text(
                      item.tagName,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.apply(fontSizeDelta: 1),
                    ),
                    const SizedBox(width: 6),
                    if (item.tagName
                            .replaceAll(RegExp(r'[a-zA-Z]'), '')
                            .compareTo(currentVersion) ==
                        0)
                      ItemBuilder.buildRoundButton(
                        context,
                        text: "当前版本",
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        radius: 3,
                        color: Theme.of(context).primaryColor,
                      ),
                    const Spacer(),
                    // Icon(
                    //   Icons.keyboard_arrow_right_rounded,
                    //   size: 20,
                    //   color: Theme.of(context).textTheme.labelMedium?.color,
                    // ),
                    ItemBuilder.buildIconButton(
                      context: context,
                      icon: Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: Theme.of(context).textTheme.labelMedium?.color,
                      ),
                      onTap: () {
                        FileUtil.downloadAndUpdate(
                          context,
                          item.assets.isNotEmpty
                              ? item.assets[0].browserDownloadUrl
                              : "",
                          item.htmlUrl,
                          version:
                              item.tagName.replaceAll(RegExp(r'[a-zA-Z]'), ''),
                          isUpdate: false,
                        );
                      },
                    ),
                  ],
                ),
                ItemBuilder.buildDivider(context, horizontal: 0, vertical: 5),
                const SizedBox(height: 9),
                ItemBuilder.buildHtmlWidget(
                  context,
                  Utils.replaceLineBreak(item.body ?? ""),
                  textStyle: Theme.of(context).textTheme.titleMedium?.apply(
                        fontSizeDelta: 1,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
