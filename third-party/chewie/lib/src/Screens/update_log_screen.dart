/*
 * Copyright (c) 2025 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateLogScreen extends StatefulWidget {
  const UpdateLogScreen({
    super.key,
    this.showTitleBar = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
  });

  final bool showTitleBar;
  final EdgeInsets padding;

  @override
  State<UpdateLogScreen> createState() => _UpdateLogScreenState();
}

class _UpdateLogScreenState extends BaseDynamicState<UpdateLogScreen>
    with TickerProviderStateMixin {
  List<ReleaseItem> releaseItems = [];
  final EasyRefreshController _refreshController = EasyRefreshController();
  String currentVersion = "";
  String latestVersion = "";
  final Map<String, FocusNode> _releaseFocusNodes = {};

  @override
  void dispose() {
    _refreshController.dispose();
    for (final node in _releaseFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getAppInfo();
  }

  void getAppInfo() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      if (!mounted) return;
      setState(() {
        currentVersion = packageInfo.version;
      });
    });
  }

  Future<void> fetchReleases() async {
    await ChewieUtils.getReleases(
      context: context,
      showLoading: false,
      showUpdateDialog: false,
      showLatestToast: false,
      noUpdateToastText: chewieLocalizations.failedToGetChangelog,
      onGetCurrentVersion: (currentVersion) {
        if (!mounted) return;
        setState(() {
          this.currentVersion = currentVersion;
        });
      },
      onGetLatestRelease: (latestVersion, latestReleaseItem) {
        if (!mounted) return;
        setState(() {
          this.latestVersion = latestVersion;
        });
      },
      onGetReleases: (releases) {
        if (!mounted) return;
        setState(() {
          releaseItems = releases;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showTitleBar
          ? ResponsiveAppBar(
              title: chewieLocalizations.changelog,
              showBack: true,
              backgroundColor: ResponsiveUtil.isLandscapeLayout()
                  ? ChewieTheme.canvasColor
                  : ChewieTheme.scaffoldBackgroundColor,
            )
          : null,
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          await fetchReleases();
        },
        child: ListView.builder(
          padding: widget.padding
              .add(const EdgeInsets.symmetric(horizontal: 8, vertical: 20)),
          itemBuilder: (context, index) => _buildItem(
            releaseItems[index],
            index,
            index == releaseItems.length - 1,
          ),
          itemCount: releaseItems.length,
        ),
      ),
    );
  }

  Widget _buildItem(ReleaseItem item, int index, bool isLast) {
    final isCurrent = ChewieUtils.compareVersion(
            item.tagName.replaceAll(RegExp(r'[a-zA-Z]'), ''), currentVersion) ==
        0;

    final releaseDate =
        item.publishedAt != null ? TimeUtil.formatDate(item.publishedAt!) : "";

    final color = HSLColor.fromAHSL(
      1.0,
      140 + (index * 220 / (releaseItems.length + 1)),
      0.6,
      isCurrent ? 0.5 : 0.4,
    ).toColor();

    return UpdateLogTimeline(
      isLast: isLast,
      marker: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCurrent ? ChewieTheme.primaryColor : color,
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(delay: 50.ms),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${item.tagName}  $releaseDate",
                  style: ChewieTheme.bodyMedium,
                ),
                const SizedBox(width: 6),
                if (isCurrent)
                  RoundIconTextButton(
                    height: 20,
                    text: chewieLocalizations.currentVersion,
                    background: ChewieTheme.primaryColor,
                    textStyle: ChewieTheme.labelMedium.apply(
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    radius: 4,
                  ),
                const Spacer(),
                ClickableGestureDetector(
                  // padding: const EdgeInsets.symmetric(
                  //   horizontal: 6,
                  //   vertical: 2,
                  // ),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: ChewieTheme.labelMedium.color,
                  ),
                  onTap: () {
                    UriUtil.launchUrlUri(context, item.htmlUrl);
                  },
                ),
              ],
            ),
            if ((item.body ?? "").isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: ChewieTheme.cardColor,
                  borderRadius: ChewieDimens.borderRadius8,
                ),
                child: SelectableAreaWrapper(
                  focusNode: _releaseFocusNodes.putIfAbsent(
                      item.htmlUrl, FocusNode.new),
                  child: CustomMarkdownWidget(
                    item.body ?? "",
                    baseStyle: ChewieTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The content determines the height; the timeline is painted alongside it.
/// Markdown can contain LayoutBuilder and cannot be measured intrinsically.
class UpdateLogTimeline extends StatelessWidget {
  const UpdateLogTimeline({
    super.key,
    required this.marker,
    required this.child,
    required this.isLast,
  });

  final Widget marker;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 6,
              top: 16,
              bottom: 0,
              width: 2,
              child: ColoredBox(color: Colors.grey.shade300),
            ),
          Positioned(left: 0, top: 0, child: marker),
          Padding(padding: const EdgeInsets.only(left: 30), child: child),
        ],
      );
}
