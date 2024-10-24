import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';

import '../../Models/github_response.dart';
import '../../Utils/file_util.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Item/item_builder.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({
    super.key,
    required this.latestReleaseItem,
    required this.latestVersion,
    required this.currentVersion,
  });

  final String latestVersion;
  final String currentVersion;
  final ReleaseItem latestReleaseItem;

  static const String routeName = "/setting/update";

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum DownloadState { normal, downloading, toInstall, installing }

class _UpdateScreenState extends State<UpdateScreen>
    with TickerProviderStateMixin {
  late String currentVersion;

  late String latestVersion;

  late ReleaseItem latestReleaseItem;

  String buttonText = "立即下载";
  DownloadState downloadState = DownloadState.normal;

  @override
  void initState() {
    super.initState();
    currentVersion = widget.currentVersion;
    latestVersion = widget.latestVersion;
    latestReleaseItem = widget.latestReleaseItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ItemBuilder.buildSimpleAppBar(
        transparent: true,
        title: "发现新版本$latestVersion",
        leading: Icons.arrow_back_rounded,
        context: context,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildItem(latestReleaseItem),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  _buildItem(ReleaseItem item) {
    return ItemBuilder.buildContainerItem(
      topRadius: true,
      bottomRadius: true,
      context: context,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        width: double.infinity,
        height: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemBuilder.buildHtmlWidget(
              context,
              "更新日志如下：<br/>${Utils.replaceLineBreak(item.body ?? "")}",
              textStyle: Theme.of(context).textTheme.titleMedium?.apply(
                    fontSizeDelta: 1,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 45,
            child: ItemBuilder.buildFramedButton(
              context,
              text: "暂不更新",
              onTap: () {
                dialogNavigatorState?.popPage();
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 45,
            child: ItemBuilder.buildRoundButton(
              context,
              background: Theme.of(context).primaryColor,
              color: Colors.white,
              text: buttonText,
              onTap: () async {
                try {
                  late ReleaseAsset asset;
                  if (ResponsiveUtil.isWindows()) {
                    asset = FileUtil.getWindowsInstallerAsset(
                        latestVersion, latestReleaseItem);
                  }
                  String url = asset.browserDownloadUrl;
                  var appDocDir = await getDownloadsDirectory();
                  String savePath =
                      "${appDocDir?.path}/${FileUtil.extractFileNameFromUrl(url)}";
                  if (downloadState == DownloadState.downloading) {
                    return;
                  } else if (downloadState == DownloadState.toInstall) {
                    setState(() {
                      buttonText = "安装中...";
                      downloadState == DownloadState.installing;
                    });
                    try {
                      var shell = Shell();
                      await shell
                          .runExecutableArguments(savePath, []).then((result) {
                        downloadState == DownloadState.normal;
                      });
                    } catch (e, t) {
                      ILogger.error("Failed to install", e, t);
                      IToast.showTop(e.toString());
                      setState(() {
                        buttonText = "立即安装";
                      });
                      downloadState == DownloadState.toInstall;
                    }
                  } else if (downloadState == DownloadState.installing) {
                  } else {
                    if (Utils.isNotEmpty(asset.browserDownloadUrl)) {
                      double progressValue = 0.0;
                      setState(() {
                        buttonText = "已下载0%";
                      });
                      downloadState = DownloadState.downloading;
                      await Dio().download(
                        url,
                        savePath,
                        onReceiveProgress: (count, total) {
                          final value = count / total;
                          if (progressValue != value) {
                            if (progressValue < 1.0) {
                              progressValue = count / total;
                            } else {
                              progressValue = 0.0;
                            }
                            setState(() {
                              buttonText =
                                  "已下载${(progressValue * 100).toInt()}%";
                            });
                          }
                        },
                      ).then((response) async {
                        if (response.statusCode == 200) {
                          IToast.showTop("下载完成");
                          setState(() {
                            buttonText = "立即安装";
                            downloadState = DownloadState.toInstall;
                          });
                        } else {
                          IToast.showTop("下载失败");
                          downloadState == DownloadState.normal;
                          UriUtil.openExternal(latestReleaseItem.url);
                        }
                      });
                    } else {
                      downloadState == DownloadState.normal;
                      UriUtil.openExternal(latestReleaseItem.url);
                    }
                  }
                } catch (e, t) {
                  ILogger.error("Failed to download package", e, t);
                  IToast.showTop("下载失败");
                  downloadState == DownloadState.normal;
                }
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
