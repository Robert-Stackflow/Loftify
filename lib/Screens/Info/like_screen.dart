import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:tuple/tuple.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';

class LikeScreen extends StatefulWidget {
  LikeScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/like";

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostDetailData> _likeList = [];
  List<ArchiveData> _archiveDataList = [];
  int _total = 0;
  HistoryLayoutMode _layoutMode = HistoryLayoutMode.nineGrid;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    if (widget.infoMode != InfoMode.me) {
      _onRefresh();
    }
  }

  _fetchLike({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _likeList.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      return await UserApi.getLikeList(blogName: blogName, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            if (Utils.isNotEmpty(
                value['meta']['desc'] ?? value['meta']['msg'])) {
              IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            }
            return IndicatorResult.fail;
          } else {
            _total = value['response']['count'];
            if (value['response']['archives'] != null) {
              _archiveDataList = [];
              List<ArchiveItem> archiveItems = [];
              List<dynamic> t = value['response']['archives'];
              for (var e in t) {
                archiveItems.add(ArchiveItem.fromJson(e));
              }
              for (var e in archiveItems) {
                for (var item in e.monthCount) {
                  if (item > 0) {
                    int month = e.monthCount.indexOf(item);
                    _archiveDataList.add(ArchiveData(
                      desc: "${e.year}年${month + 1}月",
                      count: item,
                      endTime: 0,
                      startTime: 0,
                    ));
                  }
                }
              }
              _archiveDataList.sort((a, b) => b.desc.compareTo(a.desc));
            }
            List<dynamic> t = value['response']['items'];
            if (refresh) _likeList.clear();
            for (var e in t) {
              if (e != null) {
                _likeList.add(PostDetailData.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            if (_likeList.length >= _total && !refresh) {
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
    return await _fetchLike(refresh: true);
  }

  _onLoad() async {
    return await _fetchLike();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: widget.infoMode == InfoMode.me
          ? MyTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    switch (_layoutMode) {
      case HistoryLayoutMode.waterFlow:
        return _buildWaterflow(physics);
      case HistoryLayoutMode.nineGrid:
        return _buildNineGridGroup(physics);
    }
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    List<Widget> widgets = [];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (_likeList.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_likeList.length < startIndex + count) {
        count = _likeList.length - startIndex;
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
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        physics: physics,
        children: widgets,
      ),
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.extent(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
            context, _likeList[trueIndex],
            wh: 160);
      }),
    );
  }

  Widget _buildWaterflow(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
        padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          maxCrossAxisExtent: 300,
        ),
        itemBuilder: (BuildContext context, int index) {
          return CommonInfoItemBuilder.buildWaterfallFlowPostItem(
              context, _likeList[index], onLikeTap: () async {
            var item = _likeList[index];
            HapticFeedback.mediumImpact();
            return await PostApi.likeOrUnLike(
                    isLike: !(item.liked == true),
                    postId: item.post!.id,
                    blogId: item.post!.blogId)
                .then((value) {
              setState(() {
                if (value['meta']['status'] != 200) {
                  if (Utils.isNotEmpty(
                      value['meta']['desc'] ?? value['meta']['msg'])) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  }
                } else {
                  item.liked = !(item.liked == true);
                  item.post!.postCount?.favoriteCount +=
                      item.liked == true ? 1 : -1;
                }
              });
              return value['meta']['status'];
            });
          });
        },
        itemCount: _likeList.length,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    IconData icon = Icons.transform_rounded;
    switch (_layoutMode) {
      case HistoryLayoutMode.waterFlow:
        icon = Icons.layers_outlined;
        break;
      case HistoryLayoutMode.nineGrid:
        icon = Icons.grid_3x3_rounded;
        break;
    }
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: MyTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text("我的喜欢", style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(icon, color: Theme.of(context).iconTheme.color),
            onTap: () {
              _layoutMode = HistoryLayoutMode.values[
                  (_layoutMode.index + 1) % HistoryLayoutMode.values.length];
              setState(() {});
            }),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (sheetContext) => TileList.fromOptions(
                  const [
                    Tuple2("清空无效内容", 1),
                  ],
                  (idx) {
                    Navigator.pop(sheetContext);
                    if (idx == 1) {
                      UserApi.deleteInvalidLike(
                              blogId: HiveUtil.getInt(key: HiveUtil.userIdKey))
                          .then((value) {
                        if (value['meta']['status'] != 200) {
                          IToast.showTop(
                              value['meta']['desc'] ?? value['meta']['msg']);
                        } else {
                          _likeList.removeWhere(
                              (e) => CommonInfoItemBuilder.isInvalid(e));
                          setState(() {});
                          IToast.showTop("清空成功");
                        }
                      });
                    }
                  },
                  showCancel: true,
                  context: sheetContext,
                  showTitle: false,
                  onCloseTap: () => Navigator.pop(sheetContext),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              );
            }),
        const SizedBox(width: 5),
      ],
    );
  }
}
