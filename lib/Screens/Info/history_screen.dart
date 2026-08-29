import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
import '../../Widgets/loftify_icons.dart';
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
  InitPhase _initPhase = InitPhase.successful;

  _fetchHistory({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _histories.length;
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String domain = Utils.getBlogDomain(blogInfo?.blogName);
      return await UserApi.getHistoryList(blogDomain: domain, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            _total = value['response']['count'];
            _recordHistory = value['response']['recordHistory'];
            if (value['response']['archiveData'] != null) {
              _archiveDataList.clear();
              List<dynamic> t = value['response']['archiveData'];
              for (var e in t) {
                _archiveDataList.add(ArchiveData.fromJson(e));
              }
            }
            List<dynamic> t = value['response']['items'];
            if (refresh) _histories.clear();
            for (var e in t) {
              if (e != null) {
                _histories.add(PostDetailData.fromJson(e));
              }
            }
            _initPhase = InitPhase.successful;
            if (_histories.length >= _total && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load history", e, t);
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
              refreshOnStart: true,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _onLoad,
              triggerAxis: Axis.vertical,
              childBuilder: (context, physics) {
                return _archiveDataList.isNotEmpty && _histories.isNotEmpty
                    ? _buildNineGridGroup(physics)
                    : EmptyPlaceholder(
                        text: appLocalizations.noHistory,
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
      if (_histories.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_histories.length < startIndex + count) {
        count = _histories.length - startIndex;
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
    return LoadMoreNotification(
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
    return LoftifyPostArchiveGrid(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      itemCount: count,
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
    for (var e in _histories) {
      if (CommonInfoItemBuilder.isInvalid(e)) {
        int index = _histories.indexOf(e);
        int archiveIndex = 0;
        int count = 0;
        for (var element in _archiveDataList) {
          if (count + element.count < index) {
            count++;
          } else {
            archiveIndex = _archiveDataList.indexOf(element);
          }
        }
        _archiveDataList[archiveIndex].count--;
      }
    }
    _histories.removeWhere((e) => CommonInfoItemBuilder.isInvalid(e));
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
