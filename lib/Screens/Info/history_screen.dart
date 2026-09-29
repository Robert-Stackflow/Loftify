import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
import '../../Widgets/loftify_icons.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../l10n/l10n.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const String routeName = "/info/history";

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends BaseDynamicState<HistoryScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostDetailData> _histories = [];
  final List<ArchiveData> _archiveDataList = [];
  int _total = 0;
  int _recordHistory = 0;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.connecting;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  _fetchHistory({bool refresh = false}) async {
    if (_loading || !mounted) return IndicatorResult.none;
    final token = appProvider.token;
    bool isCurrentAccount() => mounted && appProvider.token == token;
    if (token.isEmpty) {
      setState(() {
        _histories.clear();
        _archiveDataList.clear();
        _total = 0;
        _recordHistory = 0;
        _initPhase = InitPhase.failed;
      });
      return IndicatorResult.fail;
    }
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _histories.length;
    if (_histories.isEmpty) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final blogInfo = await HiveUtil.getUserInfo();
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (blogInfo == null) {
        if (_histories.isEmpty) _initPhase = InitPhase.failed;
        return IndicatorResult.fail;
      }
      String domain = Utils.getBlogDomain(blogInfo.blogName);
      final value =
          await UserApi.getHistoryList(blogDomain: domain, offset: offset);
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        if (_histories.isEmpty) _initPhase = InitPhase.failed;
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      } else {
        final int total = value['response']['count'];
        final int recordHistory = value['response']['recordHistory'];
        final archives = (value['response']['archiveData'] as List?)
            ?.map((e) => ArchiveData.fromJson(e))
            .toList();
        final posts = (value['response']['items'] as List)
            .where((e) => e != null)
            .map((e) => PostDetailData.fromJson(e))
            .toList();
        _total = total;
        _recordHistory = recordHistory;
        if (refresh || archives != null) {
          _archiveDataList
            ..clear()
            ..addAll(archives ?? <ArchiveData>[]);
        }
        if (refresh) _histories.clear();
        _histories.addAll(posts);
        _initPhase = InitPhase.successful;
        if (_histories.length >= _total && !refresh) {
          _noMore = true;
          return IndicatorResult.noMore;
        } else {
          return IndicatorResult.success;
        }
      }
    } catch (e, t) {
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (_histories.isEmpty) _initPhase = InitPhase.failed;
      ILogger.error("Failed to load history", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (mounted) {
        setState(() {
          if (!isCurrentAccount()) {
            _histories.clear();
            _archiveDataList.clear();
            _total = 0;
            _recordHistory = 0;
            _noMore = false;
            _initPhase = InitPhase.failed;
          }
        });
      }
      _loading = false;
    }
  }

  _onRefresh() async {
    return await _fetchHistory(refresh: true);
  }

  _onLoad() async {
    return await _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            if (_initPhase != InitPhase.successful) {
              final loading = _initPhase == InitPhase.connecting;
              return CustomScrollView(
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
                  )
                ],
              );
            }
            return _histories.isNotEmpty
                ? _buildNineGridGroup(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noHistory,
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
    List<Widget> widgets = [];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (_histories.length <= startIndex) {
        break;
      }
      if (e.count <= 0) continue;
      int count = e.count;
      if (_histories.length < startIndex + count) {
        count = _histories.length - startIndex;
      }
      widgets.add(SliverToBoxAdapter(
          child: ItemBuilder.buildTitle(
        context,
        title: appLocalizations.descriptionWithPostCount(
            e.desc, e.count.toString()),
        topMargin: 16,
        bottomMargin: 0,
      )));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    // Category metadata may be absent or lag behind the returned posts. Keep
    // those posts visible without inventing a date/category for them.
    if (startIndex < _histories.length) {
      widgets.add(_buildNineGrid(startIndex, _histories.length - startIndex));
    }
    return LoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: CustomScrollView(
        physics: physics,
        slivers: [
          ...widgets,
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return LoftifyPostArchiveSliverGrid(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      itemCount: count,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index, tileExtent) {
        return CommonInfoItemBuilder.buildNineGridPostItem(
          context,
          _histories[startIndex + index],
          wh: tileExtent,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myHistory,
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

  void clearInvalidHistory() {
    // Use original category ranges; decrementing counts during lookup would
    // shift later boundaries and attribute removals to the wrong category.
    var start = 0;
    for (final archive in _archiveDataList) {
      if (start >= _histories.length) break;
      final originalCount = archive.count;
      if (originalCount <= 0) continue;
      final end = (start + originalCount).clamp(0, _histories.length);
      var removed = 0;
      for (var index = start; index < end; index++) {
        if (CommonInfoItemBuilder.isInvalid(_histories[index])) removed++;
      }
      archive.count -= removed;
      start += originalCount;
    }
    final previousLength = _histories.length;
    _histories.removeWhere(CommonInfoItemBuilder.isInvalid);
    _total = (_total - (previousLength - _histories.length)).clamp(0, _total);
    setState(() {});
  }

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.clearMyHistory,
          iconData: LoftifyIcons.clear,
          status: MenuItemStatus.error,
          onPressed: () {
            DialogBuilder.showConfirmDialog(
              context,
              title: appLocalizations.clearMyHistory,
              message: appLocalizations.clearMyHistoryMessage,
              onTapConfirm: () {
                UserApi.clearHistory().then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    _histories.clear();
                    _archiveDataList.clear();
                    _total = 0;
                    setState(() {});
                    IToast.showTop(appLocalizations.clearSuccess);
                  }
                });
              },
            );
          },
        ),
        FlutterContextMenuItem(
          appLocalizations.clearInvalidContent,
          iconData: LoftifyIcons.delete,
          status: MenuItemStatus.error,
          onPressed: () async {
            UserApi.deleteInvalidHistory(blogId: await HiveUtil.getUserId())
                .then((value) {
              if (value['meta']['status'] != 200) {
                IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              } else {
                clearInvalidHistory();
                setState(() {});
                IToast.showTop(appLocalizations.clearSuccess);
              }
            });
          },
        ),
        FlutterContextMenuItem(
          _recordHistory == 1
              ? appLocalizations.closeMyHistory
              : appLocalizations.openMyHistory,
          iconData: LoftifyIcons.history,
          onPressed: () {
            HiveUtil.getUserInfo().then((blogInfo) async {
              close() {
                UserApi.closeHistory(
                  recordHistory: _recordHistory == 1 ? 0 : 1,
                  blogName: blogInfo!.blogName,
                ).then((value) {
                  if (value['meta']['status'] != 200) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                  } else {
                    _histories.clear();
                    _archiveDataList.clear();
                    _total = 0;
                    _recordHistory = _recordHistory == 1 ? 0 : 1;
                    IToast.showTop(_recordHistory == 1
                        ? appLocalizations.openSuccess
                        : appLocalizations.closeSuccess);
                    setState(() {});
                  }
                });
              }

              if (_recordHistory == 1) {
                DialogBuilder.showConfirmDialog(
                  context,
                  title: appLocalizations.closeMyHistory,
                  message: appLocalizations.closeMyHistoryMessage,
                  onTapConfirm: () {
                    close();
                  },
                );
              } else {
                close();
              }
            });
          },
        ),
      ],
    );
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
