import 'package:flutter/material.dart';
import 'package:loftify/Api/tag_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import '../../generated/l10n.dart';

class TagRelatedScreen extends StatefulWidget {
  const TagRelatedScreen({super.key, required this.tag});

  static const String routeName = "/tag/related";

  final String tag;

  @override
  State<TagRelatedScreen> createState() => _TagRelatedScreenState();
}

class _TagRelatedScreenState extends State<TagRelatedScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostListItem> _postList = [];
  final EasyRefreshController _refreshController = EasyRefreshController();

  int _pageCount = 0;
  bool _loading = false;
  bool _noMore = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: MyTheme.getBackground(context),
      body: _buildMainBody(),
    );
  }

  _fetchResult({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    if (refresh) {
      _noMore = false;
      _pageCount = 0;
    } else {
      _pageCount++;
    }
    return await TagApi.getRelatedTagPostList(
      tag: widget.tag,
      count: _pageCount,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
        } else {
          List<PostListItem> tmp = [];
          if (value['data'] != null) {
            if (value['data']['list'] != null) {
              tmp = (value['data']['list'] as List)
                  .map((e) => PostListItem.fromJson(e))
                  .toList();
              if (refresh) _postList.clear();
              for (var exist in _postList) {
                tmp.removeWhere((element) => element.itemId == exist.itemId);
              }
              _postList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _noMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag related tag post result list", e, t);
        IToast.showTop(S.current.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  _buildMainBody() {
    return EasyRefresh.builder(
      refreshOnStart: true,
      controller: _refreshController,
      onRefresh: () async {
        return await _fetchResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => ItemBuilder.buildLoadMoreNotification(
        noMore: _noMore,
        onLoad: () async {
          return await _fetchResult();
        },
        child: WaterfallFlow.builder(
          cacheExtent: 9999,
          physics: physics,
          padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
          gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            maxCrossAxisExtent: 300,
          ),
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: RecommendFlowItemBuilder.buildWaterfallFlowPostItem(
                context,
                _postList[index],
                excludeTag: widget.tag,
              ),
            );
          },
          itemCount: _postList.length,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      backgroundColor: MyTheme.getBackground(context),
      showBack: true,
      titleWidget: ItemBuilder.buildClickable(
        ItemBuilder.buildTagItem(
          context,
          widget.tag,
          TagType.normal,
          shownTag: S.current.tagRelatedTags(widget.tag),
          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          showRightIcon: true,
          showTagLabel: false,
        ),
      ),
      centerTitle: true,
      actions: [ItemBuilder.buildBlankIconButton(context)],
    );
  }
}
