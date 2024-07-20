import 'package:flutter/material.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Models/recommend_response.dart';

import '../../Api/user_api.dart';
import '../../Models/history_response.dart';
import '../../Models/post_detail_response.dart';
import '../../Resources/theme.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/favorite_folder_post_item_builder.dart';
import '../Post/post_detail_screen.dart';

class FavoriteFolderDetailScreen extends StatefulWidget {
  const FavoriteFolderDetailScreen({super.key, required this.favoriteFolderId});

  static const String routeName = "/info/favoriteFolderDetail";

  final int favoriteFolderId;

  @override
  State<FavoriteFolderDetailScreen> createState() =>
      _FavoriteFolderDetailScreenState();
}

class _FavoriteFolderDetailScreenState extends State<FavoriteFolderDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late int favoriteFolderId;
  FavoriteFolder? _favoriteFolder;
  bool _follow = false;
  SimpleBlogInfo? _creatorInfo;
  final List<FavoritePostDetailData> _posts = [];
  final List<ArchiveData> _archiveDataList = [];
  FavoriteFolderDetailLayoutMode _layoutMode =
      FavoriteFolderDetailLayoutMode.nineGrid;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _noMore = false;

  @override
  void initState() {
    super.initState();
    favoriteFolderId = widget.favoriteFolderId;
    _scrollController.addListener(() {
      if (!_noMore &&
          _scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - kLoadExtentOffset) {
        _fetchDetail();
      }
    });
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
            _follow = value['data']['followStatus'];
            _creatorInfo = SimpleBlogInfo.fromJson(value['data']['blogInfo']);
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
              String yearMonth = Utils.formatYearMonth(e.opTime ?? 0);
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
            if (_posts.length >= (_favoriteFolder?.postCount ?? 0) &&
                !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e) {
          if (mounted) IToast.showTop("加载失败");
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
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_layoutMode) {
      case FavoriteFolderDetailLayoutMode.list:
        return _buildList();
      case FavoriteFolderDetailLayoutMode.nineGrid:
        return _buildNineGridGroup();
      case FavoriteFolderDetailLayoutMode.flow:
        return _buildFlow();
    }
  }

  Widget _buildNineGridGroup() {
    List<Widget> widgets = [];
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
      widgets.add(ItemBuilder.buildTitle(
        context,
        title: "${e.desc}（${e.count}篇）",
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return ListView(
      cacheExtent: 9999,
      children: widgets,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.extent(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return GestureDetector(
          child: FavoriteFolderPostItemBuilder.buildNineGridPostItem(
              context, _posts[trueIndex],
              wh: 160),
          onTap: () {
            if (FavoriteFolderPostItemBuilder.isInvalid(_posts[trueIndex])) {
              IToast.showTop("无效内容");
            } else {
              RouteUtil.pushCupertinoRoute(
                context,
                PostDetailScreen(
                  favoritePostDetailData: _posts[trueIndex],
                  isArticle: FavoriteFolderPostItemBuilder.getPostType(
                          _posts[index]) ==
                      PostType.article,
                ),
              );
            }
          },
        );
      }),
    );
  }

  Widget _buildFlow() {
    return emptyWidget;
  }

  Widget _buildList() {
    return emptyWidget;
  }

  PreferredSizeWidget _buildAppBar() {
    IconData icon = Icons.transform_rounded;
    switch (_layoutMode) {
      case FavoriteFolderDetailLayoutMode.list:
        icon = Icons.list_rounded;
        break;
      case FavoriteFolderDetailLayoutMode.nineGrid:
        icon = Icons.grid_on_rounded;
        break;
      case FavoriteFolderDetailLayoutMode.flow:
        icon = Icons.article_outlined;
        break;
    }
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: MyTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text(_favoriteFolder?.name ?? "收藏夹详情",
          style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(icon, color: Theme.of(context).iconTheme.color),
            onTap: () {
              _layoutMode = FavoriteFolderDetailLayoutMode.values[
                  (_layoutMode.index + 1) %
                      FavoriteFolderDetailLayoutMode.values.length];
              setState(() {});
            }),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {}),
        const SizedBox(width: 5),
      ],
    );
  }
}
