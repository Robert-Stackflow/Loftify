import 'package:flutter/material.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Suit/custom_bg_avatar_list_screen.dart';
import 'package:loftify/Screens/Suit/dress_detail_screen.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/dress_api.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import 'emote_detail_screen.dart';

class CustomDressListScreen extends StatefulWidget {
  const CustomDressListScreen({
    super.key,
    this.tags = const [],
    this.propType = 2,
  });

  final int propType;

  final List<String> tags;

  static const String routeName = "/suit/customDress";

  @override
  State<CustomDressListScreen> createState() => _CustomDressListScreenState();
}

class _CustomDressListScreenState extends State<CustomDressListScreen>
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
  String? tag;

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _noMore = false;
      if (offset < 0) offset = 0;
    }
    if(offset<0) return IndicatorResult.noMore;
    _loading = true;
    return await DressApi.getDressList(
      offset: refresh ? 0 : offset,
      tag: tag ?? "",
      propType: widget.propType,
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
                        f.packageId == tmp.returnGiftEmotePackage!.packageId) ==
                    -1) {
                  _giftEmoteList.add(tmp.returnGiftEmotePackage!);
                }
              }
            }
          }
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
        if (mounted) IToast.showTop("加载失败");
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
    return Column(
      children: [
        CustomBgAvatarListScreenState.buildTagBar(context, widget.tags, tag,
            (tag) {
          this.tag = tag;
          setState(() {});
          _refreshController.resetHeader();
          _refreshController.callRefresh();
        }),
        Expanded(
          child: EasyRefresh.builder(
            refreshOnStart: true,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoad: _onLoad,
            triggerAxis: Axis.vertical,
            childBuilder: (context, physics) {
              return widget.propType == 3
                  ? _buildEmoteBody(physics)
                  : _buildDressBody(physics);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDressBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
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

  Widget _buildEmoteBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
        padding: const EdgeInsets.all(10),
        itemCount: _giftEmoteList.length,
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          maxCrossAxisExtent: 300,
        ),
        itemBuilder: (context, index) {
          return _buildGiftEmoteItem(_giftEmoteList[index]);
        },
      ),
      noMore: _noMore,
      onLoad: _onLoad,
    );
  }

  _buildGiftDressItem(GiftDress item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          DressDetailScreen(
            returnGiftDressId: item.returnGiftDressId,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: MyTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const SizedBox(width: 15),
            SizedBox(
              width: 200,
              height: 200,
              child: item.partCount >= 4
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        return ItemBuilder.buildCachedImage(
                          imageUrl: item.partList[index].partUrl,
                          context: context,
                          showLoading: false,
                          placeholderBackground: Colors.transparent,
                          width: 80,
                          height: 80,
                        );
                      },
                    )
                  : ItemBuilder.buildCachedImage(
                      imageUrl: item.coverImg,
                      context: context,
                      showLoading: false,
                      placeholderBackground: Colors.transparent,
                      width: 200,
                      height: 200,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              "${item.partCount}个挂件",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            ItemBuilder.buildRoundButton(
              context,
              text: "查看详情",
              background: Theme.of(context).primaryColor,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  DressDetailScreen(
                    returnGiftDressId: item.returnGiftDressId,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  _buildGiftEmoteItem(GiftEmote item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          EmoteDetailScreen(
            emotePackId: item.packageId,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: MyTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const SizedBox(width: 15),
            SizedBox(
              width: 200,
              height: 200,
              child: item.emoteCount >= 4
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        return ItemBuilder.buildCachedImage(
                          imageUrl: item.emoteList[index].url,
                          context: context,
                          showLoading: false,
                          placeholderBackground: Colors.transparent,
                          width: 80,
                          height: 80,
                        );
                      },
                    )
                  : ItemBuilder.buildCachedImage(
                      imageUrl: item.name,
                      context: context,
                      showLoading: false,
                      placeholderBackground: Colors.transparent,
                      width: 200,
                      height: 200,
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              "${item.emoteCount}个永久表情",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            ItemBuilder.buildRoundButton(
              context,
              text: "查看详情",
              background: Theme.of(context).primaryColor,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  EmoteDetailScreen(
                    emotePackId: item.packageId,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
