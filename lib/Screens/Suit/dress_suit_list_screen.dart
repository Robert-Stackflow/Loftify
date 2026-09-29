import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/gift_api.dart';

import '../../Models/dress_response.dart';
import '../../Widgets/Suit/dress_preview_card.dart';
import '../../l10n/l10n.dart';

class DressSuitListScreen extends StatefulWidget {
  const DressSuitListScreen({
    super.key,
    this.refreshOnStart = true,
  });

  final bool refreshOnStart;

  static const String routeName = "/info/dressSuit";

  @override
  State<DressSuitListScreen> createState() => DressSuitListScreenState();
}

class DressSuitListScreenState extends BaseDynamicState<DressSuitListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<DressingItem> _dressSuitList = [];
  bool _loading = false;
  int offset = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  void callRefresh() => _refreshController.callRefresh();

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _noMore = false;
      offset = 0;
    }
    if (offset < 0) return IndicatorResult.noMore;
    _loading = true;
    return await GiftApi.getDressSuitList(
      offset: refresh ? 0 : offset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          DressingListData data = DressingListData.fromJson(value['data']);
          offset = data.offset;
          List<DressingItem> t = data.list;
          if (refresh) {
            _dressSuitList.clear();
          }
          _dressSuitList.addAll(t);
          if (mounted) setState(() {});
          if (t.isEmpty || offset < 0) {
            _noMore = true;
            if (!refresh) return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e, t) {
        ILogger.error("Failed to load dress list", e, t);
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
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
    return EasyRefresh.builder(
      refreshOnStart: widget.refreshOnStart,
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) {
        return _buildBody(physics);
      },
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return LoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: MediaQuery.sizeOf(context).height,
        padding: const EdgeInsets.all(10),
        itemCount: _dressSuitList.length,
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          maxCrossAxisExtent: 400,
        ),
        itemBuilder: (context, index) {
          return _buildDressItem(_dressSuitList[index]);
        },
      ),
      noMore: _noMore,
      onLoad: _onLoad,
    );
  }

  _buildDressItem(DressingItem item) {
    return DressPreviewCard(
      title: item.name,
      subtitle: item.intro,
      badge: item.specialLabel.isNotEmpty
          ? item.specialLabel
          : item.showPrice.isNotEmpty
              ? item.showPrice
              : null,
      previewHeight: 260,
      previewPadding: EdgeInsets.zero,
      onTap: null,
      preview: ChewieItemBuilder.buildCachedImage(
        imageUrl: item.img,
        context: context,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        showLoading: false,
      ),
    );
  }
}
