import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Models/favorites_response.dart';

import '../../Api/user_api.dart';
import '../../Models/history_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Screens/Download/batch_download_screen.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/favorite_folder_post_item_builder.dart';
import '../../Widgets/PostItem/general_post_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import '../Post/post_detail_screen.dart';

class FavoriteFolderDetailScreen extends StatefulWidget {
  const FavoriteFolderDetailScreen({super.key, required this.favoriteFolderId});

  static const String routeName = "/info/favoriteFolderDetail";

  final int favoriteFolderId;

  @override
  State<FavoriteFolderDetailScreen> createState() =>
      _FavoriteFolderDetailScreenState();
}

class _FavoriteFolderDetailScreenState
    extends BaseDynamicState<FavoriteFolderDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late int favoriteFolderId;
  FavoriteFolder? _favoriteFolder;
  final List<FavoritePostDetailData> _posts = [];
  final List<ArchiveData> _archiveDataList = [];
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void initState() {
    super.initState();
    favoriteFolderId = widget.favoriteFolderId;
  }

  _fetchDetail({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _posts.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      return await UserApi.getFavoriteFolderDetail(
        folderId: favoriteFolderId,
        offset: offset,
      ).then((value) {
        try {
          if (value['code'] != 0) {
            IToast.showTop(value['msg']);
            return IndicatorResult.fail;
          } else {
            _favoriteFolder = FavoriteFolder.fromJson(value['data']['folder']);
            List<dynamic> t = value['data']['posts'];
            if (refresh) _posts.clear();
            for (var e in t) {
              if (e != null) {
                _posts.add(FavoritePostDetailData.fromJson(e));
              }
            }
            Map<String, int> monthCount = {};
            for (var e in _posts) {
              String yearMonth = formatLocalizedYearMonth(e.opTime ?? 0);
              monthCount.putIfAbsent(yearMonth, () => 0);
              monthCount[yearMonth] = monthCount[yearMonth]! + 1;
            }
            _archiveDataList.clear();
            for (var e in monthCount.keys) {
              _archiveDataList.add(ArchiveData(
                desc: e,
                count: monthCount[e] ?? 0,
                endTime: 0,
                startTime: 0,
              ));
            }
            _archiveDataList.sort((a, b) => b.desc.compareTo(a.desc));
            if (mounted) setState(() {});
            _noMore =
                t.isEmpty || _posts.length >= (_favoriteFolder?.postCount ?? 0);
            return !refresh && _noMore
                ? IndicatorResult.noMore
                : IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load folder detail", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  _onRefresh() async {
    return await _fetchDetail(refresh: true);
  }

  _onLoad() async {
    return await _fetchDetail();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _noMore ? null : _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) =>
            _archiveDataList.isNotEmpty && _posts.isNotEmpty
                ? _buildNineGridGroup(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noFavorite,
                    physics: physics,
                    shrinkWrap: false,
                  ),
      ),
    );
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    final slivers = <Widget>[];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (_posts.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_posts.length < startIndex + count) {
        count = _posts.length - startIndex;
      }
      slivers.add(
        SliverToBoxAdapter(
          child: ItemBuilder.buildTitle(
            context,
            title: appLocalizations.descriptionWithPostCount(
                e.desc, e.count.toString()),
            topMargin: 16,
            bottomMargin: 0,
          ),
        ),
      );
      slivers.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return CustomScrollView(
      physics: physics,
      cacheExtent: MediaQuery.sizeOf(context).height,
      slivers: slivers,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            int trueIndex = startIndex + index;
            final post = _posts[trueIndex];
            return GestureDetector(
              key: ValueKey('favorite-folder-${post.post?.id ?? trueIndex}'),
              child: FavoriteFolderPostItemBuilder.buildNineGridPostItem(
                context,
                post,
                wh: 160,
              ),
              onTap: () {
                if (FavoriteFolderPostItemBuilder.isInvalid(post)) {
                  IToast.showTop(appLocalizations.invalidContent);
                } else {
                  RouteUtil.pushPanelCupertinoRoute(
                    context,
                    PostDetailScreen(
                      favoritePostDetailData: post,
                      isArticle:
                          FavoriteFolderPostItemBuilder.getPostType(post) ==
                              PostType.article,
                    ),
                  );
                }
              },
            );
          },
          childCount: count,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: _favoriteFolder?.name ?? appLocalizations.favoriteFolderDetail,
      actions: [
        ChewieIconButton(
          icon: LoftifyIcons.download,
          tooltip: appLocalizations.batchDownload,
          onPressed: _openBatchDownload,
        ),
      ],
    );
  }

  void _openBatchDownload() {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      BatchDownloadScreen(
        sourceTitle:
            _favoriteFolder?.name ?? appLocalizations.favoriteFolderDetail,
        initialItems: _posts
            .map(FavoriteFolderPostItemBuilder.getGeneralPostItem)
            .toList(),
        loadAllItems: _loadAllBatchItems,
      ),
    );
  }

  Future<List<GeneralPostItem>> _loadAllBatchItems() async {
    if (_posts.isEmpty) await _onRefresh();
    while (!_noMore) {
      final previousLength = _posts.length;
      final result = await _onLoad();
      if (result == IndicatorResult.fail ||
          result == IndicatorResult.none ||
          _posts.length == previousLength) {
        break;
      }
    }
    return _posts
        .map(FavoriteFolderPostItemBuilder.getGeneralPostItem)
        .toList(growable: false);
  }
}
