import 'package:awesome_chewie/awesome_chewie.dart';

import '../../l10n/l10n.dart';

import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/user_response.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
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

  _fetchList({bool refresh = false}) async {
    if (_supporterList.isNotEmpty && !refresh) return IndicatorResult.noMore;
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      int blogId = widget.infoMode == InfoMode.me
          ? await HiveUtil.getUserId()
          : widget.blogId!;
      return await UserApi.getSupporterList(
        blogId: blogId,
      ).then((value) {
        try {
          if (value['code'] != 200) {
            IToast.showTop(value['msg']);
            return IndicatorResult.fail;
          } else {
            List<dynamic> t = value['data']['ranks'];
            if (refresh) _supporterList.clear();
            for (var e in t) {
              if (e != null) {
                _supporterList.add(SupporterItem.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            if (refresh) {
              return IndicatorResult.success;
            } else {
              _noMore = true;
              return IndicatorResult.noMore;
            }
          }
        } catch (e, t) {
          ILogger.error("Failed to load supporter list", e, t);
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
    return await _fetchList(refresh: true);
  }

  _onLoad() async {
    return await _fetchList();
  }

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
        onLoad: _onLoad,
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
      child: WaterfallFlow.extent(
        maxCrossAxisExtent: 600,
        padding: EdgeInsets.zero,
        physics: physics,
        children: List.generate(_supporterList.length, (index) {
          return _buildItem(index, _supporterList[index]);
        }),
      ),
    );
  }

  _buildItem(int index, SupporterItem item) {
    return ClickableGestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
            blogId: item.blogInfo.blogId,
            blogName: item.blogInfo.blogName,
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              size: 40,
              imageUrl: item.blogInfo.bigAvaImg,
              tagPrefix: "$index",
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.blogInfo.blogNickName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.blogInfo.selfIntro!.isNotEmpty)
                    const SizedBox(height: 5),
                  if (item.blogInfo.selfIntro!.isNotEmpty)
                    Text(
                      item.blogInfo.selfIntro!,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 5),
              child: ChewieIcon(
                LoftifyIcons.premium,
                size: 22,
                color: ChewieColors.getHotTagTextColor(context),
              ),
            ),
            Text(
              item.score.toString(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.supporterList,
    );
  }
}
