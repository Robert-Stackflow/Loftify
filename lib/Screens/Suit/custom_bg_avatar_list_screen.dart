import 'dart:io';

import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/gift_api.dart';
import 'package:loftify/Models/suit_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Widgets/BottomSheet/bottom_sheet_builder.dart';
import 'package:loftify/Widgets/BottomSheet/custom_bg_avatar_detail_bottom_sheet.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Custom/hero_photo_view_screen.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class CustomBgAvatarListScreen extends StatefulWidget {
  const CustomBgAvatarListScreen({
    super.key,
    this.tags = const [],
    this.blogId,
  });

  final List<String> tags;

  final int? blogId;

  static const String routeName = "/info/customBgAvatarList";

  @override
  State<CustomBgAvatarListScreen> createState() =>
      CustomBgAvatarListScreenState();
}

class CustomBgAvatarListScreenState extends State<CustomBgAvatarListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<ProductItem> _productList = [];
  bool _loading = false;
  int offset = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  String? tag;

  static buildTagBar(BuildContext context, List<String> tags, String? selected,
      Function(String? tag) onSelectedTag) {
    if (ResponsiveUtil.isDesktop()) {
      return buildWrapTagBar(context, tags, selected, onSelectedTag);
    } else {
      return buildListTagBar(tags, selected, onSelectedTag);
    }
  }

  static buildListTagBar(List<String> tags, String? selected,
      Function(String? tag) onSelectedTag) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        itemBuilder: (context, index) {
          bool check = false;
          if (index == 0) {
            check = selected == null;
          } else {
            check = selected == tags[index - 1];
          }
          Color bg = check
              ? Theme.of(context).primaryColor
              : MyTheme.getCardBackground(context);
          Color? textColor = check ? Colors.white : null;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: ItemBuilder.buildRoundButton(
              context,
              text: index == 0 ? S.current.all : "#${tags[index - 1]}",
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              radius: 20,
              background: bg,
              textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                  fontSizeDelta: 1,
                  color: textColor,
                  fontWeightDelta: check ? 2 : 0),
              onTap: () {
                onSelectedTag(index == 0 ? null : tags[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }

  static buildWrapTagBar(BuildContext context, List<String> tags,
      String? selected, Function(String? tag) onSelectedTag) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10)
          .add(const EdgeInsets.only(bottom: 10)),
      child: Wrap(
        spacing: 10,
        runSpacing: 5,
        children: [
          ItemBuilder.buildRoundButton(
            context,
            text: S.current.all,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            radius: 20,
            background: selected == null
                ? Theme.of(context).primaryColor
                : MyTheme.getCardBackground(context),
            textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                fontSizeDelta: 1,
                fontWeightDelta: selected == null ? 2 : 0,
                color: selected == null ? Colors.white : null),
            onTap: () {
              onSelectedTag(null);
            },
          ),
          ...tags.map((e) => ItemBuilder.buildRoundButton(
                context,
                text: "#$e",
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                radius: 20,
                background: selected == e
                    ? Theme.of(context).primaryColor
                    : MyTheme.getCardBackground(context),
                textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                    fontSizeDelta: 1,
                    fontWeightDelta: selected == e ? 2 : 0,
                    color: selected == e ? Colors.white : null),
                onTap: () {
                  onSelectedTag(e);
                },
              )),
        ],
      ),
    );
  }

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) {
      _noMore = false;
      offset = 0;
    }
    if (offset < 0) return IndicatorResult.noMore;
    _loading = true;
    Map<String, dynamic> value = {};
    try {
      List<dynamic> t = [];
      if (widget.blogId != null) {
        value = await GiftApi.getUserProductList(
          type: 1,
          blogId: widget.blogId!,
          offset: refresh ? 0 : offset,
        );
      } else {
        value = await GiftApi.getCustomBgAvatarList(
          type: 0,
          offset: refresh ? 0 : offset,
          tag: tag ?? "",
        );
      }
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      } else {
        if (widget.blogId != null) {
          offset = value['data']['offset'];
          t = value['data']['imageProducts'];
        } else {
          offset = value['data']['offset'];
          t = value['data']['products'];
        }
        if (refresh) {
          _productList.clear();
        }
        _productList.addAll(t.map((e) => ProductItem.fromJson(e)).toList());
        _productList.removeWhere((element) =>
            _productList.where((e) => e.isSame(element)).length > 1);
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
      if (mounted) IToast.showTop(S.current.loadFailed);
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
          buildTagBar(context, widget.tags, tag, (tag) {
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
              return _productList.isNotEmpty
                  ? _buildBody(physics)
                  : ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: S.current.noBgAvatar,
                      physics: physics);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
        padding: const EdgeInsets.all(10),
        itemCount: _productList.length,
        gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          maxCrossAxisExtent: 200,
        ),
        itemBuilder: (context, index) {
          return _buildProductItem(_productList[index]);
        },
      ),
      noMore: _noMore,
      onLoad: _onLoad,
    );
  }

  _buildProductItem(ProductItem item) {
    return ItemBuilder.buildClickable(
      GestureDetector(
        onTap: () {
          BottomSheetBuilder.showBottomSheet(
            context,
            (_) => CustomBgAvatarDetailBottomSheet(item: item),
            responsive: true,
            useVerticalMargin: true,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: MyTheme.getCardBackground(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 15),
              _buildProductBg(item),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.type == 0 ? item.product!.name : item.lootBox!.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.apply(fontWeightDelta: 2, fontSizeDelta: -1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 16,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.tags.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(right: 5),
                    child: ItemBuilder.buildRoundButton(
                      context,
                      text: "#${item.tags[index].tag}",
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      radius: 5,
                      textStyle: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  _buildProductBg(ProductItem item) {
    String bgUrl = "";
    bool isAvatar = false;
    if (item.type == 0) {
      ProductData data = item.product!;
      if (data.wallpapers.isNotEmpty) {
        bgUrl = data.wallpapers.first.img.raw;
      } else if (data.avatars.isNotEmpty) {
        bgUrl = data.avatars.first.img.raw;
        isAvatar = true;
      }
    } else {
      LootBoxData data = item.lootBox!;
      if (data.productItems.isNotEmpty) {
        bgUrl = data.productItems.first.img.raw;
      }
    }
    return buildProductBg(context, bgUrl, isAvatar,
        tag: item.type == 0 ? S.current.singleSuit : S.current.cardPool,
        isHero: false);
  }

  static buildProductBg(
    BuildContext context,
    String url,
    bool isAvatar, {
    String tag = "",
    double height = 240,
    bool isHero = true,
    List<String>? urls,
    Function(int)? onIndexChanged,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Blur(
            blur: 10,
            borderRadius: BorderRadius.circular(10),
            blurColor: Colors.black,
            colorOpacity: 0.25,
            child: Container(
              padding: const EdgeInsets.all(2),
              child: ItemBuilder.buildCachedImage(
                imageUrl: url,
                context: context,
                showLoading: false,
                fit: BoxFit.cover,
                placeholderBackground: Colors.transparent,
                width: double.infinity,
                height: height,
              ),
            ),
          ),
        ),
        Center(
          child: isAvatar
              ? buildAvatarCard(
                  context,
                  url,
                  height / 2,
                  height / 2,
                  0.5,
                  isHero: isHero,
                  urls: urls,
                  onIndexChanged: onIndexChanged,
                )
              : buildBgCard(
                  context,
                  url,
                  height / 2,
                  height * 3 / 4,
                  0.5,
                  isHero: isHero,
                  urls: urls,
                  onIndexChanged: onIndexChanged,
                ),
        ),
        if (tag.isNotEmpty)
          Positioned(
            left: 4,
            bottom: 4,
            child: ItemBuilder.buildTranslucentTag(
              context,
              text: tag,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              fontSizeDelta: -2,
              opacity: 0.2,
            ),
          ),
      ],
    );
  }

  static buildBgCard(
    BuildContext context,
    String url,
    double width,
    double height,
    double opacity, {
    bool isHero = true,
    List<String>? urls,
    Function(int)? onIndexChanged,
  }) {
    Widget image = ItemBuilder.buildCachedImage(
      imageUrl: url,
      context: context,
      showLoading: false,
      fit: BoxFit.cover,
      width: width,
      placeholderBackground: Colors.transparent,
      height: height,
    );
    image = isHero
        ? ItemBuilder.buildClickable(GestureDetector(
            onTap: () {
              RouteUtil.pushDialogRoute(
                context,
                showClose: false,
                fullScreen: true,
                useFade: true,
                HeroPhotoViewScreen(
                  imageUrls: urls ?? [url],
                  initIndex: urls != null ? urls.indexOf(url) : 0,
                  useMainColor: true,
                  onIndexChanged: onIndexChanged,
                ),
              );
            },
            child: image,
          ))
        : image;
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isHero ? image : IgnorePointer(child: image),
          ),
          Positioned(
            top: 20,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Sunday, July 6",
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.apply(color: Colors.white, fontSizeDelta: -4),
                  ),
                  Text(
                    "9:41",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.apply(color: Colors.white, fontSizeDelta: 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static buildAvatarCard(
    BuildContext context,
    String url,
    double width,
    double height,
    double opacity, {
    bool isHero = true,
    List<String>? urls,
    Function(int)? onIndexChanged,
  }) {
    Widget image = ItemBuilder.buildCachedImage(
      imageUrl: url,
      context: context,
      showLoading: false,
      fit: BoxFit.cover,
      width: width,
      placeholderBackground: Colors.transparent,
      height: height,
    );
    image = isHero
        ? ItemBuilder.buildClickable(GestureDetector(
            onTap: () {
              RouteUtil.pushDialogRoute(
                context,
                showClose: false,
                fullScreen: true,
                useFade: true,
                HeroPhotoViewScreen(
                  imageUrls: urls ?? [url],
                  initIndex: urls != null ? urls.indexOf(url) : 0,
                  useMainColor: true,
                  onIndexChanged: onIndexChanged,
                ),
              );
            },
            child: image,
          ))
        : image;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isHero ? image : IgnorePointer(child: image),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(5), bottom: Radius.circular(8)),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Center(
              child: ItemBuilder.buildAvatar(
                clickable: false,
                context: context,
                imageUrl: url,
                showLoading: false,
                size: 24,
                showBorder: false,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Center(
              child: Text(
                "Loftify",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.apply(color: Colors.black, fontSizeDelta: -7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
