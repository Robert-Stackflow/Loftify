import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Models/enums.dart';
import '../../Models/post_detail_response.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';

class PostScreen extends StatefulWidget {
  PostScreen({
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

  static const String routeName = "/info/post";

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  PostDetailData? _topPost;
  final List<PostDetailData> _postList = [];
  List<ArchiveData> _archiveDataList = [];
  HistoryLayoutMode _layoutMode = HistoryLayoutMode.nineGrid;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();

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
    _loading = true;
    int offset = 0;
    if (refresh) {
      offset = 0;
    } else {
      if (_archiveDataList.isNotEmpty && _archiveDataList[0].isTop) {
        offset = _postList.length - _archiveDataList[0].count;
      }
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      int blogId =
          widget.infoMode == InfoMode.me ? blogInfo!.blogId : widget.blogId!;
      return await UserApi.getPostList(
        blogName: blogName,
        blogId: blogId,
        offset: offset,
      ).then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(context,
                text: value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
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
            List<PostDetailData> tmp = [];
            if (refresh) _postList.clear();
            for (var e in (value['response']['posts'] as List)) {
              if (e != null &&
                  _postList.indexWhere(
                          (element) => element.post!.id == e['post']['id']) ==
                      -1) {
                tmp.add(PostDetailData.fromJson(e));
              }
            }
            _postList.addAll(tmp);
            if (value['response']['topPost'] != null) {
              _topPost = PostDetailData.fromJson(value['response']['topPost']);
              _archiveDataList.insert(
                0,
                ArchiveData(
                  desc: "置顶",
                  count: 1,
                  endTime: 0,
                  startTime: 0,
                  isTop: true,
                ),
              );
              if ((_postList.isNotEmpty &&
                      _postList[0].post!.id != _topPost!.post!.id) ||
                  _postList.isEmpty) {
                _postList.insert(0, _topPost!);
              }
            }
            if (mounted) setState(() {});
            if (tmp.isEmpty && !refresh) {
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e) {
          if (mounted) IToast.showTop(context, text: "加载失败");
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
          ? AppTheme.getBackground(context)
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
      if (_postList.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_postList.length < startIndex + count) {
        count = _postList.length - startIndex;
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
      padding: EdgeInsets.zero,
      physics: physics,
      children: widgets,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.count(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
            context, _postList[trueIndex],
            wh: (MediaQuery.sizeOf(context).width - 22) / 3);
      }),
    );
  }

  Widget _buildWaterflow(ScrollPhysics physics) {
    return WaterfallFlow.builder(
      physics: physics,
      cacheExtent: 9999,
      padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
      gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (BuildContext context, int index) {
        return CommonInfoItemBuilder.buildWaterfallFlowPostItem(
            context, _postList[index], onLikeTap: () async {
          var item = _postList[index];
          HapticFeedback.mediumImpact();
          return await PostApi.likeOrUnLike(
                  isLike: !(item.liked == true),
                  postId: item.post!.id,
                  blogId: item.post!.blogId)
              .then((value) {
            setState(() {
              if (value['meta']['status'] != 200) {
                IToast.showTop(context,
                    text: value['meta']['desc'] ?? value['meta']['msg']);
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
      itemCount: _postList.length,
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
      backgroundColor: AppTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text("我的作品", style: Theme.of(context).textTheme.titleLarge),
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
        // ItemBuilder.buildIconButton(
        //     context: context,
        //     icon: Icon(Icons.more_vert_rounded,
        //         color: Theme.of(context).iconTheme.color),
        //     onTap: () {}),
        // const SizedBox(width: 5),
      ],
    );
  }
}
