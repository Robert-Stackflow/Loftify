import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/gift_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/suit_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Screens/Suit/custom_bg_avatar_list_screen.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

class CustomBgAvatarDetailPanel extends StatelessWidget {
  const CustomBgAvatarDetailPanel({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
  });

  final String title;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final design = context.design;
    final availableHeight = (media.size.height -
            media.padding.top -
            media.viewInsets.bottom -
            design.spacing.sm)
        .clamp(0.0, 760.0);
    final textScale = media.textScaler.scale(14) / 14;
    final scrollFooter = availableHeight < 640 || textScale > 1.3;
    final scrollingContent = SingleChildScrollView(
      key: const ValueKey('custom-bg-avatar-detail-scroll'),
      physics: const ClampingScrollPhysics(),
      child: scrollFooter
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                Divider(
                  height: design.borders.hairline,
                  thickness: design.borders.hairline,
                  color: design.colors.outline,
                ),
                Padding(
                  key: const ValueKey(
                    'custom-bg-avatar-detail-scrolling-footer',
                  ),
                  padding: EdgeInsets.all(design.spacing.xl),
                  child: footer,
                ),
              ],
            )
          : body,
    );
    return ConstrainedBox(
      key: const ValueKey('custom-bg-avatar-detail-panel'),
      constraints: BoxConstraints(maxHeight: availableHeight),
      child: LoftifyPanel(
        title: title,
        expandBody: true,
        body: scrollingContent,
        footer: scrollFooter ? null : footer,
        footerPadding: EdgeInsets.all(design.spacing.xl),
      ),
    );
  }
}

class CustomBgAvatarDetailBottomSheet extends StatefulWidget {
  const CustomBgAvatarDetailBottomSheet({super.key, required this.item});

  final ProductItem item;

  @override
  CustomBgAvatarDetailBottomSheetState createState() =>
      CustomBgAvatarDetailBottomSheetState();
}

class CustomBgAvatarDetailBottomSheetState
    extends State<CustomBgAvatarDetailBottomSheet> {
  ProductItem get item => widget.item;
  Map<int, SimpleBlogInfo> map = {};
  final SwiperController _swiperController = SwiperController();
  int _currentIndex = 0;
  String currentUserNickName = "";

  bool get isLootBox => item.type != 0;

  int count = 0;

  @override
  void initState() {
    super.initState();
    fetchInfo();
    if (isLootBox) {
      count = item.lootBox!.productItems.length;
    } else {
      count = item.product!.wallpapers.length + item.product!.avatars.length;
    }
    setState(() {});
  }

  Future<void> fetchInfo() async {
    var value = await GiftApi.getProductDetail(
      id: !isLootBox ? item.product!.id : item.lootBox!.id,
      type: item.type,
    );
    try {
      if (!isLootBox) {
        var blogInfo = SimpleBlogInfo.fromJson(value['data']['blogInfo']);
        map[blogInfo.blogId] = blogInfo;
      } else {
        for (var item in value['data']['imageProduct']['lootBox']
            ['productItems']) {
          var blogInfo = SimpleBlogInfo.fromJson(item['blogInfo']);
          blogInfo.blogId = item['userId'];
          map[blogInfo.blogId] = blogInfo;
        }
      }
      refreshCurrentUser();
      setState(() {});
    } catch (e, t) {
      ILogger.error(
          "Failed to load custom bg avatar detail:${item.toJson()}", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
    }
  }

  void refreshCurrentUser() {
    if (isLootBox) {
      var blogInfo = map[item.lootBox!.productItems[_currentIndex].userId];
      currentUserNickName = blogInfo?.blogNickName ?? "";
    } else {
      var blogInfo = map[item.product!.blogId];
      currentUserNickName = blogInfo?.blogNickName ?? "";
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomBgAvatarDetailPanel(
      title: appLocalizations.dressDetail,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildContent(), _buildDesc()],
      ),
      footer: _buildFooter(),
    );
  }

  String getUrlByIndex(int index) {
    if (isLootBox) {
      return item.lootBox!.productItems[index].img.raw;
    } else {
      if (index < item.product!.wallpapers.length) {
        return item.product!.wallpapers[index].img.raw;
      } else {
        return item
            .product!.avatars[index - item.product!.wallpapers.length].img.raw;
      }
    }
  }

  bool getIsAvatarByIndex(int index) {
    if (isLootBox) {
      return false;
    } else {
      if (index < item.product!.wallpapers.length) {
        return false;
      } else {
        return true;
      }
    }
  }

  List<String> getAllImages() {
    if (isLootBox) {
      return item.lootBox!.productItems.map((e) => e.img.raw).toList();
    } else {
      return item.product!.wallpapers.map((e) => e.img.raw).toList()
        ..addAll(item.product!.avatars.map((e) => e.img.raw).toList());
    }
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 300,
                child: Swiper(
                  loop: false,
                  control: null,
                  controller: _swiperController,
                  itemCount: count,
                  itemBuilder: (BuildContext context, int index) {
                    String url = getUrlByIndex(index);
                    bool isAvatar = getIsAvatarByIndex(index);
                    var res = CustomBgAvatarListScreenState.buildProductBg(
                      context,
                      url,
                      height: 300,
                      isAvatar,
                      urls: getAllImages(),
                      onIndexChanged: (index) {
                        _currentIndex = index;
                        setState(() {});
                        _swiperController.move(index);
                      },
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: res,
                    );
                  },
                  pagination: count > 1
                      ? SwiperPagination(
                          margin: const EdgeInsets.only(bottom: 12),
                          builder: DotSwiperPaginationBuilder(
                            color: Colors.grey[300],
                            activeColor: Theme.of(context).primaryColor,
                            size: 4,
                            activeSize: 6,
                            space: count > 40 ? 1.4 : 3,
                          ),
                        )
                      : null,
                  onIndexChanged: (index) {
                    _currentIndex = index;
                    refreshCurrentUser();
                  },
                ),
              ),
              if (count > 1 && ResponsiveUtil.isDesktop())
                Positioned(
                  left: 16,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ChewieIconButton(
                      icon: LoftifyIcons.previous,
                      iconSize: 30,
                      tapTargetSize: 44,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(
                        alpha: _currentIndex == 0 ? 0.26 : 0.4,
                      ),
                      cornerRadius: 22,
                      onPressed: _currentIndex == 0
                          ? null
                          : _swiperController.previous,
                    ),
                  ),
                ),
              if (count > 1 && ResponsiveUtil.isDesktop())
                Positioned(
                  right: 16,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ChewieIconButton(
                      icon: LoftifyIcons.next,
                      iconSize: 30,
                      tapTargetSize: 44,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black.withValues(
                        alpha: _currentIndex == count - 1 ? 0.26 : 0.4,
                      ),
                      cornerRadius: 22,
                      onPressed: _currentIndex == count - 1
                          ? null
                          : _swiperController.next,
                    ),
                  ),
                ),
              if (count > 1)
                Positioned(
                  top: 6,
                  left: 15,
                  child: ItemBuilder.buildTranslucentTag(
                    context,
                    text: '${_currentIndex + 1}/$count',
                    opacity: 0.5,
                  ),
                ),
              if (currentUserNickName.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 15,
                  child: ClickableGestureDetector(
                    onTap: () {
                      if (ResponsiveUtil.isLandscapeLayout()) {
                        Navigator.pop(context);
                      }
                      try {
                        if (isLootBox) {
                          var blogInfo = map[
                              item.lootBox!.productItems[_currentIndex].userId];
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            UserDetailScreen(
                              blogName: blogInfo!.blogName,
                              blogId: blogInfo.blogId,
                            ),
                          );
                        } else {
                          var blogInfo = map[item.product!.blogId];
                          RouteUtil.pushPanelCupertinoRoute(
                            context,
                            UserDetailScreen(
                              blogName: blogInfo!.blogName,
                              blogId: blogInfo.blogId,
                            ),
                          );
                        }
                      } catch (e, t) {
                        ILogger.error("Failed to open user detail", e, t);
                        IToast.showTop(appLocalizations.jumpFailed);
                      }
                    },
                    child: ItemBuilder.buildTranslucentTag(
                      context,
                      text: currentUserNickName,
                      opacity: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesc() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16)
          .add(const EdgeInsets.only(bottom: 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLootBox ? item.lootBox!.name : item.product!.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (!isLootBox && item.product!.intro.isNotEmpty)
            const SizedBox(height: 10),
          if (!isLootBox && item.product!.intro.isNotEmpty)
            Text(
              item.product!.intro,
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final design = context.design;
    final actions = <Widget>[
      LoftifyButton(
        label: appLocalizations.singleImage,
        icon: LoftifyIcons.download,
        variant: LoftifyButtonVariant.secondary,
        expand: true,
        onPressed: _downloadCurrent,
      ),
      if (count > 1)
        LoftifyButton(
          label: appLocalizations.all,
          icon: LoftifyIcons.batchDownload,
          variant: LoftifyButtonVariant.secondary,
          expand: true,
          onPressed: _downloadAll,
        ),
      LoftifyButton(
        label: appLocalizations.confirm,
        variant: LoftifyButtonVariant.primary,
        expand: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final vertical = constraints.maxWidth < 560 || textScale > 1.3;
        if (vertical) {
          return Column(
            key: const ValueKey('custom-bg-avatar-detail-actions-vertical'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                actions[index],
                if (index != actions.length - 1)
                  SizedBox(height: design.spacing.md),
              ],
            ],
          );
        }
        return Row(
          key: const ValueKey('custom-bg-avatar-detail-actions-horizontal'),
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              Expanded(child: actions[index]),
              if (index != actions.length - 1)
                SizedBox(width: design.spacing.md),
            ],
          ],
        );
      },
    );
  }

  Future<void> _downloadCurrent() async {
    CustomLoadingDialog.showLoading(title: appLocalizations.downloading);
    try {
      final url = getUrlByIndex(_currentIndex);
      await FileUtil.saveImage(context, url);
    } finally {
      CustomLoadingDialog.dismissLoading();
    }
  }

  Future<void> _downloadAll() async {
    CustomLoadingDialog.showLoading(title: appLocalizations.downloading);
    try {
      final urls = <String>[];
      if (isLootBox) {
        for (final product in item.lootBox!.productItems) {
          urls.add(product.img.raw);
        }
      } else {
        for (final wallpaper in item.product!.wallpapers) {
          urls.add(wallpaper.img.raw);
        }
        for (final avatar in item.product!.avatars) {
          urls.add(avatar.img.raw);
        }
      }
      await FileUtil.saveImages(context, urls);
    } finally {
      CustomLoadingDialog.dismissLoading();
    }
  }
}
