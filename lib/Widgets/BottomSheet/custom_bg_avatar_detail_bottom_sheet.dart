import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/gift_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/suit_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Screens/Suit/custom_bg_avatar_list_screen.dart';
import '../../Utils/file_util.dart';
import '../../Utils/ilogger.dart';
import '../../generated/l10n.dart';

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
      if (mounted) IToast.showTop(S.current.loadFailed);
    }
  }

  refreshCurrentUser() {
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
    return Wrap(
      runAlignment: WrapAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.vertical(
                top: const Radius.circular(20),
                bottom: ResponsiveUtil.isWideLandscape()
                    ? const Radius.circular(20)
                    : Radius.zero),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
              _buildContent(),
              _buildDesc(),
              ItemBuilder.buildDivider(context, horizontal: 12, vertical: 0),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Text(
        S.current.dressDetail,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  getUrlByIndex(int index) {
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

  getIsAvatarByIndex(int index) {
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

  getAllImages() {
    if (isLootBox) {
      return item.lootBox!.productItems.map((e) => e.img.raw).toList();
    } else {
      return item.product!.wallpapers.map((e) => e.img.raw).toList()
        ..addAll(item.product!.avatars.map((e) => e.img.raw).toList());
    }
  }

  _buildContent() {
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
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _swiperController.previous();
                      },
                      child: ItemBuilder.buildClickItem(
                        clickable: _currentIndex != 0,
                        const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (count > 1 && ResponsiveUtil.isDesktop())
                Positioned(
                  right: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _currentIndex == count - 1
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _swiperController.next();
                      },
                      child: ItemBuilder.buildClickItem(
                        clickable: _currentIndex != count - 1,
                        const Icon(
                          Icons.keyboard_arrow_right_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (count > 1)
                Positioned(
                  top: 6,
                  left: 15,
                  child: ItemBuilder.buildTransparentTag(
                    context,
                    text: '${_currentIndex + 1}/$count',
                    opacity: 0.5,
                  ),
                ),
              if (currentUserNickName.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 15,
                  child: ItemBuilder.buildClickItem(
                    GestureDetector(
                      onTap: () {
                        if (ResponsiveUtil.isLandscape()) {
                          Navigator.pop(context);
                        }
                        try {
                          if (isLootBox) {
                            var blogInfo = map[item
                                .lootBox!.productItems[_currentIndex].userId];
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
                          IToast.showTop(S.current.jumpFailed);
                        }
                      },
                      child: ItemBuilder.buildTransparentTag(
                        context,
                        text: currentUserNickName,
                        opacity: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _buildDesc() {
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

  _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ItemBuilder.buildIconTextButton(
              context,
              icon: const Icon(Icons.download_done_rounded, size: 24),
              direction: Axis.vertical,
              text: S.current.singleImage,
              fontSizeDelta: -2,
              onTap: () async {
                CustomLoadingDialog.showLoading(title: S.current.downloading);
                String url = getUrlByIndex(_currentIndex);
                await FileUtil.saveImage(context, url);
                CustomLoadingDialog.dismissLoading();
              },
            ),
          ),
          const SizedBox(width: 20),
          if (count > 1)
            Center(
              child: ItemBuilder.buildIconTextButton(
                context,
                icon: const Icon(Icons.done_all_rounded, size: 24),
                direction: Axis.vertical,
                text: S.current.all,
                fontSizeDelta: -2,
                onTap: () async {
                  CustomLoadingDialog.showLoading(title: S.current.downloading);
                  List<String> urls = [];
                  if (isLootBox) {
                    for (var item in item.lootBox!.productItems) {
                      urls.add(item.img.raw);
                    }
                  } else {
                    for (var item in item.product!.wallpapers) {
                      urls.add(item.img.raw);
                    }
                    for (var item in item.product!.avatars) {
                      urls.add(item.img.raw);
                    }
                  }
                  await FileUtil.saveImages(context, urls);
                  CustomLoadingDialog.dismissLoading();
                },
              ),
            ),
          if (count > 1) const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ItemBuilder.buildRoundButton(
                context,
                background: Theme.of(context).primaryColor,
                text: S.current.confirm,
                onTap: () async {
                  Navigator.of(context).pop();
                },
                fontSizeDelta: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
