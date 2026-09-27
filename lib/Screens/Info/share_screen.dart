import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Models/download_task.dart';
import '../../Screens/Download/batch_download_screen.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
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
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  int _total = 0;
  InitPhase _initPhase = InitPhase.connecting;

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
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchShare({bool refresh = false}) async {
    if (_loading || !mounted) return IndicatorResult.none;
    final token = appProvider.token;
    bool isCurrentAccount() => mounted && appProvider.token == token;
    _loading = true;
    final offset = refresh ? 0 : _shareList.length;
    if (_shareList.isEmpty) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final blogInfo =
          widget.infoMode == InfoMode.me ? await HiveUtil.getUserInfo() : null;
      if (!isCurrentAccount()) return IndicatorResult.none;
      final blogName =
          widget.infoMode == InfoMode.me ? blogInfo?.blogName : widget.blogName;
      if (blogName == null || blogName.isEmpty) {
        if (_shareList.isEmpty) _initPhase = InitPhase.failed;
        return IndicatorResult.fail;
      }
      final value = await UserApi.getShareList(
        blogName: blogName,
        offset: offset,
      );
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        if (_shareList.isEmpty) _initPhase = InitPhase.failed;
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      }
      final response = value['response'];
      final total = response['count'] as int;
      var archiveData = refresh ? <ArchiveData>[] : _archiveDataList;
      if (response['archives'] != null) {
        final months = <({int year, int month, int count})>[];
        for (final archive in response['archives'] as List) {
          final item = ArchiveItem.fromJson(archive);
          for (var month = 0; month < item.monthCount.length; month++) {
            final count = item.monthCount[month];
            if (count > 0) {
              months.add((year: item.year, month: month + 1, count: count));
            }
          }
        }
        months.sort((a, b) {
          final yearOrder = b.year.compareTo(a.year);
          return yearOrder != 0 ? yearOrder : b.month.compareTo(a.month);
        });
        archiveData = [
          for (final month in months)
            ArchiveData(
              desc: appLocalizations.yearAndMonth(month.month, month.year),
              count: month.count,
              endTime: 0,
              startTime: 0,
            ),
        ];
      }
      final page = (response['items'] as List)
          .where((item) => item != null)
          .map((item) => PostDetailData.fromJson(item))
          .toList();
      final posts = refresh ? <PostDetailData>[] : [..._shareList];
      posts.addAll(page);
      _archiveDataList = archiveData;
      _shareList
        ..clear()
        ..addAll(posts);
      _initPhase = InitPhase.successful;
      _noMore = page.isEmpty || posts.length >= total;
      _total = total;
      return !refresh && _noMore
          ? IndicatorResult.noMore
          : IndicatorResult.success;
    } catch (error, stackTrace) {
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (_shareList.isEmpty) _initPhase = InitPhase.failed;
      ILogger.error('Failed to load share list', error, stackTrace);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (mounted) {
        setState(() {
          if (!isCurrentAccount()) {
            _shareList.clear();
            _archiveDataList = [];
            _noMore = false;
            _total = 0;
            _initPhase = InitPhase.failed;
          }
        });
      }
      _loading = false;
    }
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchShare(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
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

  Widget _buildBody() {
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
            if (_initPhase != InitPhase.successful) {
              final loading = _initPhase == InitPhase.connecting;
              return CustomScrollView(
                controller: widget.scrollController,
                physics: physics,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoftifyStateView(
                      visual: loading
                          ? LoftifyStateVisual.loading
                          : LoftifyStateVisual.error,
                      title: loading
                          ? appLocalizations.loading
                          : appLocalizations.loadFailed,
                      scrollWhenConstrained: false,
                      actionLabel: loading ? null : chewieLocalizations.retry,
                      onAction: loading
                          ? null
                          : () => _refreshController.callRefresh(),
                    ),
                  ),
                ],
              );
            }
            return _shareList.isNotEmpty
                ? _buildNineGridGroup(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noRecommend,
                    physics: physics,
                    shrinkWrap: false,
                  );
          },
        ),
        if (_initPhase == InitPhase.successful)
          Positioned(
            right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
            bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
            child: _buildFloatingButtons(),
          ),
      ],
    );
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    final slivers = <Widget>[];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (_shareList.length <= startIndex) {
        break;
      }
      if (e.count <= 0) continue;
      int count = e.count;
      if (_shareList.length < startIndex + count) {
        count = _shareList.length - startIndex;
      }
      slivers.add(SliverToBoxAdapter(
        child: ItemBuilder.buildTitle(
          context,
          title: appLocalizations.descriptionWithPostCount(
              e.desc, e.count.toString()),
          topMargin: 16,
          bottomMargin: 0,
        ),
      ));
      slivers.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    if (startIndex < _shareList.length) {
      slivers.add(_buildNineGrid(startIndex, _shareList.length - startIndex));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
    return CustomScrollView(
      controller: widget.scrollController,
      physics: physics,
      slivers: slivers,
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return LoftifyPostArchiveSliverGrid(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      itemCount: count,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index, tileExtent) {
        final trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
          context,
          _shareList[trueIndex],
          wh: tileExtent,
        );
      },
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

  FlutterContextMenu _buildMoreButtons() {
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
    if (_shareList.isEmpty) {
      final result = await _onRefresh();
      if (result != IndicatorResult.success &&
          result != IndicatorResult.noMore) {
        throw StateError('Could not load recommended posts');
      }
    }
    while (!_noMore) {
      final previousLength = _shareList.length;
      final result = await _onLoad();
      if (result == IndicatorResult.fail ||
          result == IndicatorResult.none ||
          _shareList.length == previousLength) {
        throw StateError('Could not load all recommended posts');
      }
    }
    final items = _shareList
        .map(CommonInfoItemBuilder.getGeneralPostItem)
        .toList(growable: false);
    if (items
            .where((item) => item.postId > 0)
            .map((item) => item.postId)
            .toSet()
            .length <
        _total) {
      throw StateError('Recommended posts are incomplete');
    }
    return items;
  }

  Widget _buildFloatingButtons() {
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
