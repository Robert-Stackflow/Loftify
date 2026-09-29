import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Screens/Suit/dress_detail_screen.dart';

import '../../Api/dress_api.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Suit/dress_preview_card.dart';
import '../../l10n/l10n.dart';

class DressScreen extends StatefulWidget {
  const DressScreen({
    super.key,
    this.tag,
  });

  final String? tag;

  static const String routeName = "/info/dress";

  @override
  State<DressScreen> createState() => _DressScreenState();
}

class _DressScreenState extends BaseDynamicState<DressScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<GiftData> _giftList = [];
  final List<GiftDress> _giftDressList = [];
  final List<GiftEmote> _giftEmoteList = [];
  bool _loading = false;
  int offset = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    return await DressApi.getDressList(
      offset: refresh ? 0 : offset,
      tag: widget.tag ?? "",
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          offset = value['data']['offset'];
          List<dynamic> t = value['data']['propReturnGifts'];
          if (refresh) {
            _giftList.clear();
            _giftDressList.clear();
            _giftEmoteList.clear();
          }
          for (var e in t) {
            if (e != null) {
              GiftData tmp = GiftData.fromJson(e);
              _giftList.add(tmp);
              if (tmp.type == 2) {
                if (_giftDressList.indexWhere((f) =>
                        f.returnGiftDressId ==
                        tmp.returnGiftDress!.returnGiftDressId) ==
                    -1) {
                  _giftDressList.add(tmp.returnGiftDress!);
                }
              } else if (tmp.type == 3) {
                if (_giftEmoteList.indexWhere((f) =>
                        f.giftId == tmp.returnGiftEmotePackage!.giftId) ==
                    -1) {
                  _giftEmoteList.add(tmp.returnGiftEmotePackage!);
                }
              }
            }
          }
          if (mounted) setState(() {});
          if (t.isEmpty) {
            _noMore = true;
            return IndicatorResult.noMore;
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
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: MediaQuery.sizeOf(context).height,
        padding: const EdgeInsets.all(10),
        itemCount: _giftDressList.length,
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          maxCrossAxisExtent: 300,
        ),
        itemBuilder: (context, index) {
          return _buildGiftDressItem(_giftDressList[index]);
        },
      ),
      noMore: _noMore,
      onLoad: _onLoad,
    );
  }

  _buildGiftDressItem(GiftDress item) {
    void openDetail() {
      RouteUtil.pushPanelCupertinoRoute(
        context,
        DressDetailScreen(returnGiftDressId: item.returnGiftDressId),
      );
    }

    return DressPreviewCard(
      title: item.name,
      subtitle: StringUtil.isNotEmpty(item.creatorNickName)
          ? item.creatorNickName
          : appLocalizations.pendantCount(item.partCount),
      badge: appLocalizations.pendantCount(item.partCount),
      onTap: openDetail,
      preview: ChewieItemBuilder.buildCachedImage(
        imageUrl: item.coverImg,
        context: context,
        showLoading: false,
        placeholderBackground: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      centerTitle: StringUtil.isNotEmpty(widget.tag),
      titleWidget: StringUtil.isNotEmpty(widget.tag)
          ? ClickableWrapper(
              child: ItemBuilder.buildTagItem(
                context,
                widget.tag!,
                TagType.normal,
                shownTag: appLocalizations.relatedDress(widget.tag ?? ""),
                backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                color: Theme.of(context).primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                showRightIcon: true,
                showTagLabel: false,
              ),
            )
          : Text(
              appLocalizations.dressList,
              style: Theme.of(context).textTheme.titleLarge,
            ),
      actions: const [BlankIconButton()],
    );
  }
}
