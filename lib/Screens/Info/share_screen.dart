import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Models/download_task.dart';
import '../../Screens/Download/batch_download_screen.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/general_post_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class ShareScreen extends StatefulWidgetForNested {
  ShareScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'recommend',
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

class _ShareScreenState extends BaseDynamicState<ShareScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<ShareScreen> {
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
    super.initState();
    bindNestedRefreshSignal(() {
      _refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 140),
      );
    });
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onRefresh();
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
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
                      desc: appLocalizations.yearAndMonth(month + 1, e.year),
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
            _noMore = _shareList.length >= _total;
            if (_noMore && !refresh) {
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load share list", e, t);
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
          ? ChewieTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return const LoadingWidget(background: Colors.transparent);
      case InitPhase.failed:
        return CustomErrorWidget(
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return Stack(
          children: [
            EasyRefresh.builder(
              header: widget.nested ? buildNestedRefreshHeader() : null,
              refreshOnStart: !widget.nested,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _noMore ? null : _onLoad,
              triggerAxis: Axis.vertical,
              childBuilder: (context, physics) {
                return _archiveDataList.isNotEmpty
                    ? _buildNineGridGroup(physics)
                    : EmptyPlaceholder(
                        text: appLocalizations.noRecommend,
                        physics: physics,
                        shrinkWrap: false,
                      );
              },
            ),
            Positioned(
              right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
              bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
              child: _buildFloatingButtons(),
            ),
          ],
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
        title: appLocalizations.descriptionWithPostCount(
            e.desc, e.count.toString()),
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return ListView(
      controller: widget.scrollController,
      physics: physics,
      padding: const EdgeInsets.only(bottom: 20),
      children: widgets,
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
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myRecommends,
      actions: [
        ChewieIconButton(
          icon: LoftifyIcons.moreVertical,
          tooltip: appLocalizations.moreInfo,
          onPressed: () =>
              BottomSheetBuilder.showContextMenu(context, _buildMoreButtons()),
        ),
      ],
    );
  }

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.batchDownload,
          iconData: LoftifyIcons.download,
          onPressed: _openBatchDownload,
        ),
        FlutterContextMenuItem(
          appLocalizations.clearInvalidContent,
          iconData: LoftifyIcons.delete,
          status: MenuItemStatus.error,
          onPressed: () async {
            UserApi.deleteInvalidShare(blogId: await HiveUtil.getUserId())
                .then((value) {
              if (value['meta']['status'] != 200) {
                IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              } else {
                _shareList
                    .removeWhere((e) => CommonInfoItemBuilder.isInvalid(e));
                setState(() {});
                IToast.showTop(appLocalizations.clearSuccess);
              }
            });
          },
        ),
      ],
    );
  }

  void _openBatchDownload() {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      BatchDownloadScreen(
        sourceTitle: appLocalizations.myRecommends,
        source: DownloadSourceDescriptor(
          type: DownloadSourceType.recommendations,
          sourceId: widget.blogId?.toString() ?? 'self',
          title: appLocalizations.myRecommends,
          metadata: widget.blogId == null
              ? const <String, String>{}
              : <String, String>{
                  'blogId': widget.blogId.toString(),
                  if (widget.blogName?.trim().isNotEmpty == true)
                    'blogName': widget.blogName!.trim(),
                },
        ),
        initialItems:
            _shareList.map(CommonInfoItemBuilder.getGeneralPostItem).toList(),
        loadAllItems: _loadAllBatchItems,
      ),
    );
  }

  Future<List<GeneralPostItem>> _loadAllBatchItems() async {
    if (_shareList.isEmpty) await _onRefresh();
    while (!_noMore) {
      final previousLength = _shareList.length;
      final result = await _onLoad();
      if (result == IndicatorResult.fail ||
          result == IndicatorResult.none ||
          _shareList.length == previousLength) {
        break;
      }
    }
    return _shareList
        .map(CommonInfoItemBuilder.getGeneralPostItem)
        .toList(growable: false);
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: const ChewieIcon(LoftifyIcons.moreVertical),
                onTap: () {
                  BottomSheetBuilder.showContextMenu(
                      context, _buildMoreButtons());
                },
              ),
            ],
          )
        : emptyWidget;
  }
}
