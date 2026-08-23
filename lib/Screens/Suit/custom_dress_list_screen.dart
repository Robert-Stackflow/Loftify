import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/gift_api.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Screens/Suit/custom_bg_avatar_list_screen.dart';
import 'package:loftify/Screens/Suit/dress_detail_screen.dart';

import '../../Api/dress_api.dart';
import '../../Widgets/Suit/dress_preview_card.dart';
import '../../l10n/l10n.dart';
import 'emote_detail_screen.dart';

class CustomDressListScreen extends StatefulWidget {
  const CustomDressListScreen({
    super.key,
    this.tags = const [],
    this.propType = 2,
    this.blogId,
    this.refreshOnStart = true,
  });

  final int propType;

  final List<String> tags;

  final int? blogId;
  final bool refreshOnStart;

  static const String routeName = "/suit/customDress";

  @override
  State<CustomDressListScreen> createState() => CustomDressListScreenState();
}

class CustomDressListScreenState extends BaseDynamicState<CustomDressListScreen>
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

  void callRefresh() => _refreshController.callRefresh();

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _noMore = false;
      if (offset < 0) offset = 0;
    }
    if (offset < 0) return IndicatorResult.noMore;
    _loading = true;
    List<dynamic> t = [];
    try {
      Map<String, dynamic> value = {};
      if (widget.blogId == null) {
        value = await DressApi.getDressList(
          offset: refresh ? 0 : offset,
          tag: tag ?? "",
          propType: widget.propType,
        );
        offset = value['data']['offset'];
        t = value['data']['propReturnGifts'];
      } else {
        value = await GiftApi.getUserProductList(
          offset: refresh ? 0 : offset,
          blogId: widget.blogId!,
          type: widget.propType,
        );
        offset = value['data']['offset'];
        if (widget.propType == 2) {
          t = value['data']['returnGiftDressList'];
        } else {
          t = value['data']['returnGiftEmotePackageList'];
        }
      }
      if (value['code'] != 0 && value['code'] != 200) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      } else {
        if (refresh) {
          _giftList.clear();
          _giftDressList.clear();
          _giftEmoteList.clear();
        }
        if (widget.blogId == null) {
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
        } else {
          if (widget.propType == 2) {
            _giftDressList.addAll(t.map((e) => GiftDress.fromJson(e)).toList());
          } else {
            _giftEmoteList.addAll(t.map((e) => GiftEmote.fromJson(e)).toList());
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
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (mounted) setState(() {});
      _loading = false;
    }
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
        if (widget.blogId == null)
          CustomBgAvatarListScreenState.buildTagBar(context, widget.tags, tag,
              (tag) {
            this.tag = tag;
            setState(() {});
            _refreshController.resetHeader();
            _refreshController.callRefresh();
          }),
        Expanded(
          child: EasyRefresh.builder(
            refreshOnStart: widget.refreshOnStart,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoad: _onLoad,
            triggerAxis: Axis.vertical,
            childBuilder: (context, physics) {
              return widget.propType == 3
                  ? _giftEmoteList.isNotEmpty
                      ? _buildEmoteBody(physics)
                      : EmptyPlaceholder(
                          text: appLocalizations.noEmotePackage,
                          physics: physics,
                          shrinkWrap: false,
                        )
                  : _giftDressList.isNotEmpty
                      ? _buildDressBody(physics)
                      : EmptyPlaceholder(
                          text: appLocalizations.noDress,
                          physics: physics,
                          shrinkWrap: false,
                        );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDressBody(ScrollPhysics physics) {
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

  Widget _buildEmoteBody(ScrollPhysics physics) {
    return LoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: MediaQuery.sizeOf(context).height,
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
    return DressPreviewCard(
      title: item.name,
      subtitle: StringUtil.isNotEmpty(item.creatorNickName)
          ? item.creatorNickName
          : appLocalizations.pendantCount(item.partCount),
      badge: appLocalizations.pendantCount(item.partCount),
      onTap: () => _openDressDetail(item),
      preview: _buildDressPreview(item),
    );
  }

  void _openDressDetail(GiftDress item) {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      DressDetailScreen(returnGiftDressId: item.returnGiftDressId),
    );
  }

  Widget _buildDressPreview(GiftDress item) {
    if (item.partCount < 4 || item.partList.length < 4) {
      return ChewieItemBuilder.buildCachedImage(
        imageUrl: item.coverImg,
        context: context,
        showLoading: false,
        placeholderBackground: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => ChewieItemBuilder.buildCachedImage(
        imageUrl: item.partList[index].partUrl,
        context: context,
        showLoading: false,
        placeholderBackground: Colors.transparent,
        fit: BoxFit.contain,
      ),
    );
  }

  _buildGiftEmoteItem(GiftEmote item) {
    return DressPreviewCard(
      title: item.name,
      subtitle: appLocalizations.emoteCount(item.emoteCount),
      badge: appLocalizations.emoteCount(item.emoteCount),
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          EmoteDetailScreen(emotePackId: item.packageId),
        );
      },
      preview: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: item.emoteList.length.clamp(0, 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => ChewieItemBuilder.buildCachedImage(
          imageUrl: item.emoteList[index].url,
          context: context,
          showLoading: false,
          placeholderBackground: Colors.transparent,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
