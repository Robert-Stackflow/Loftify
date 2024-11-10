import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../generated/l10n.dart';

class PostScreen extends StatefulWidgetForNested {
  PostScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
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
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    super.initState();
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () => _onRefresh());
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  _fetchLike({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = 0;
    if (refresh) {
      offset = 0;
    } else {
      if (_archiveDataList.isNotEmpty && _archiveDataList[0].isTop) {
        offset = _postList.length - _archiveDataList[0].count;
      }
    }
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
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
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
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
                      desc: S.current.yearAndMonth(e.year, month + 1),
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
                  desc: S.current.pin,
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
            _initPhase = InitPhase.successful;
            if (tmp.isEmpty && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load post list", e, t);
          if (mounted) IToast.showTop(S.current.loadFailed);
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
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return ItemBuilder.buildLoadingWidget(context,
            background: Colors.transparent);
      case InitPhase.failed:
        return ItemBuilder.buildErrorWidget(
          context: context,
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _archiveDataList.isNotEmpty
                ? _buildNineGridGroup(physics)
                : ItemBuilder.buildEmptyPlaceholder(
                    context: context,
                    text: S.current.noArticle,
                    physics: physics);
          },
        );
      default:
        return Container();
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
        title: S.current.descriptionWithPostCount(e.desc, e.count.toString()),
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
            context, _postList[trueIndex],
            wh: 160);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      title: S.current.myPosts,
    );
  }
}
