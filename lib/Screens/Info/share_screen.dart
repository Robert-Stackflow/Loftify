import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:tuple/tuple.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';

class ShareScreen extends StatefulWidgetForNested {
  ShareScreen({
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
  static const String routeName = "/info/share";

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostDetailData> _shareList = [];
  List<ArchiveData> _archiveDataList = [];
  int _total = 0;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () => _onRefresh());
      });
    }else{
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  _fetchShare({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _shareList.length;
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      return await UserApi.getShareList(blogName: blogName, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
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
            if (refresh) _shareList.clear();
            for (var e in t) {
              if (e != null) {
                _shareList.add(PostDetailData.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            _initPhase = InitPhase.successful;
            if (_shareList.length >= _total && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load share list", e, t);
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
    return await _fetchShare(refresh: true);
  }

  _onLoad() async {
    return await _fetchShare();
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
        return ItemBuilder.buildLoadingDialog(context,
            background: Colors.transparent);
      case InitPhase.failed:
        return ItemBuilder.buildError(
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
                    context: context, text: "暂无推荐",physics: physics);
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
      if (_shareList.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_shareList.length < startIndex + count) {
        count = _shareList.length - startIndex;
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
        physics: physics,
        padding: const EdgeInsets.only(bottom: 20),
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
            context, _shareList[trueIndex],
            wh: 160);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      title: "我的推荐",
      actions: [
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
                  (idx) async {
                    Navigator.pop(sheetContext);
                    if (idx == 0) {
                      UserApi.deleteInvalidLike(
                              blogId: await HiveUtil.getUserId())
                          .then((value) {
                        if (value['meta']['status'] != 200) {
                          IToast.showTop(
                              value['meta']['desc'] ?? value['meta']['msg']);
                        } else {
                          _shareList.removeWhere(
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
