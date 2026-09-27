import 'package:awesome_chewie/awesome_chewie.dart';

import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/user_response.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Profile/supporter_list_item.dart';
import 'user_detail_screen.dart';

class SupporterScreen extends StatefulWidget {
  SupporterScreen({
    super.key,
    this.blogId,
    this.infoMode = InfoMode.me,
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogId != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;

  static const String routeName = "/info/supporter";

  @override
  State<SupporterScreen> createState() => _SupporterScreenState();
}

class _SupporterScreenState extends BaseDynamicState<SupporterScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<SupporterItem> _supporterList = [];
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchList({bool refresh = false}) async {
    if (_supporterList.isNotEmpty && !refresh) return IndicatorResult.noMore;
    if (_loading) return IndicatorResult.none;
    if (refresh) _noMore = false;
    _loading = true;
    try {
      final blogId = widget.infoMode == InfoMode.me
          ? await HiveUtil.getUserId()
          : widget.blogId!;
      if (!mounted) return IndicatorResult.none;
      final value = await UserApi.getSupporterList(blogId: blogId);
      if (!mounted) return IndicatorResult.none;
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      }
      final ranks = value['data']['ranks'] as List;
      final supporters = ranks
          .whereType<Map>()
          .map(
              (rank) => SupporterItem.fromJson(Map<String, dynamic>.from(rank)))
          .toList();
      setState(() {
        _supporterList
          ..clear()
          ..addAll(supporters);
        _noMore = true;
      });
      return refresh ? IndicatorResult.success : IndicatorResult.noMore;
    } catch (error, stackTrace) {
      ILogger.error('Failed to load supporter list', error, stackTrace);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      _loading = false;
    }
  }

  Future<IndicatorResult> _onRefresh() => _fetchList(refresh: true);

  Future<IndicatorResult> _onLoad() => _fetchList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _noMore ? null : _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return LoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: WaterfallFlow.builder(
        physics: physics,
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 560,
          mainAxisSpacing: 0,
          crossAxisSpacing: 8,
        ),
        itemCount: _supporterList.length,
        itemBuilder: (context, index) => _buildItem(_supporterList[index]),
      ),
    );
  }

  Widget _buildItem(SupporterItem item) {
    return LoftifySupporterListItem(
      blogId: item.blogInfo.blogId,
      avatarUrl: item.blogInfo.bigAvaImg,
      name: item.blogInfo.blogNickName,
      blogName: item.blogInfo.blogName,
      intro: item.blogInfo.selfIntro,
      score: item.score,
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: item.blogInfo.blogId,
            blogName: item.blogInfo.blogName,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.supporterList,
    );
  }
}
