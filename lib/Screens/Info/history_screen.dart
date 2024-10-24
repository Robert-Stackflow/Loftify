import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:tuple/tuple.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const String routeName = "/info/history";

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
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

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
  }

  _fetchHistory({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _histories.length;
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
            if (mounted) setState(() {});
            if (_histories.length >= _total && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          ILogger.error("Failed to load history", e, t);
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
    return await _fetchHistory(refresh: true);
  }

  _onLoad() async {
    return await _fetchHistory();
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
        child: _buildNineGridGroup(),
      ),
    );
  }

  Widget _buildNineGridGroup() {
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
        children: widgets,
      ),
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        maxCrossAxisExtent: 160,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return CommonInfoItemBuilder.buildNineGridPostItem(
            context, _histories[startIndex + index],
            wh: 160);
      },
      itemCount: count,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: MyTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text("我的足迹", style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showListBottomSheet(
                context,
                (sheetContext) => TileList.fromOptions(
                  [
                    const Tuple2("清空我的足迹", 0),
                    const Tuple2("清空无效内容", 1),
                    Tuple2(_recordHistory == 1 ? "关闭我的足迹" : "打开我的足迹", 2),
                  ],
                  (idx) {
                    Navigator.pop(sheetContext);
                    if (idx == 0) {
                      UserApi.clearHistory().then((value) {
                        if (value['meta']['status'] != 200) {
                          IToast.showTop(
                              value['meta']['desc'] ?? value['meta']['msg']);
                        } else {
                          _histories.clear();
                          _archiveDataList.clear();
                          _total = 0;
                          setState(() {});
                          IToast.showTop("清空成功");
                        }
                      });
                    } else if (idx == 1) {
                      UserApi.deleteInvalidHistory(
                              blogId: HiveUtil.getInt(HiveUtil.userIdKey))
                          .then((value) {
                        if (value['meta']['status'] != 200) {
                          IToast.showTop(
                              value['meta']['desc'] ?? value['meta']['msg']);
                        } else {
                          clearInvalidHistory();
                          setState(() {});
                          IToast.showTop("清空成功");
                        }
                      });
                    } else if (idx == 2) {
                      HiveUtil.getUserInfo().then((blogInfo) async {
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
                            IToast.showTop(
                                _recordHistory == 1 ? "打开成功" : "关闭成功");
                            setState(() {});
                          }
                        });
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
}
