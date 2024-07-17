import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/dress_api.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Models/enums.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/Custom/hero_photo_view_screen.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class DressDetailScreen extends StatefulWidget {
  const DressDetailScreen({
    super.key,
    required this.returnGiftDressId,
  });

  final int returnGiftDressId;

  static const String routeName = "/info/dressDetail";

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends State<DressDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GiftDress? _giftDress;
  bool _loading = false;
  String? userAvatarImg;
  String? currentAvatarImg;
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
    super.initState();
    _onRefresh();
    currentAvatarImg = HiveUtil.getString(
        key: HiveUtil.customAvatarBoxKey, defaultValue: null);
    setState(() {});
  }

  _fetchDetail({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    userAvatarImg = (await HiveUtil.getUserInfo())!.bigAvaImg;
    await DressApi.getDressDetail(
      returnGiftDressId: widget.returnGiftDressId,
    ).then((value) {
      try {
        if (value['code'] != 200) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          _giftDress = GiftDress.fromJson(value['data']['returnGiftDress']);
          _giftDress!.partList.sort((a, b) => a.partType.compareTo(b.partType));
          if (mounted) setState(() {});
          return IndicatorResult.success;
        }
      } catch (e) {
        if (mounted) IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  _onRefresh() async {
    return await _fetchDetail(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _giftDress != null
                ? _buildBody(physics)
                : ItemBuilder.buildLoadingDialog(
                    context,
                    background: AppTheme.getBackground(context),
                  );
          }),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return WaterfallFlow.builder(
      physics: physics,
      cacheExtent: 9999,
      padding: const EdgeInsets.all(10),
      itemCount: _giftDress!.partList.length,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        maxCrossAxisExtent: 300,
      ),
      itemBuilder: (context, index) {
        return _buildItem(_giftDress!.partList[index]);
      },
    );
  }

  _dressOrUnDress(GiftPartItem item) async {
    HapticFeedback.mediumImpact();
    if (currentAvatarImg == item.partUrl) {
      await HiveUtil.put(key: HiveUtil.customAvatarBoxKey, value: "");
      currentAvatarImg = "";
      setState(() {});
      IToast.showTop(context, text: "取消佩戴成功");
    } else {
      await HiveUtil.put(key: HiveUtil.customAvatarBoxKey, value: item.partUrl);
      currentAvatarImg = item.partUrl;
      setState(() {});
      IToast.showTop(context, text: "佩戴成功");
    }
  }

  _buildItem(GiftPartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.partType == 1
                ? ItemBuilder.buildAvatar(
                    context: context,
                    size: 60,
                    showLoading: false,
                    imageUrl: userAvatarImg ?? "",
                    avatarBoxImageUrl: item.partUrl,
                    tagPrefix: "dressAvatarBox${item.partName}",
                    showDetailMode: ShowDetailMode.avatarBox,
                  )
                : GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HeroPhotoViewScreen(
                            imageUrls: [item.partUrl],
                            useMainColor: false,
                            title: item.partName,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: item.partUrl,
                      child: ItemBuilder.buildCachedImage(
                        context: context,
                        width: 90,
                        height: 90,
                        showLoading: false,
                        imageUrl: item.img,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 15),
          Text(
            item.partName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            item.partType == 1 ? "头像框" : "评论气泡",
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          item.partType == 1
              ? ItemBuilder.buildRoundButton(
                  context,
                  text: currentAvatarImg == item.partUrl ? "正在佩戴" : "立即佩戴",
                  background: currentAvatarImg == item.partUrl
                      ? null
                      : Theme.of(context).primaryColor,
                  onTap: () {
                    _dressOrUnDress(item);
                  },
                )
              : ItemBuilder.buildRoundButton(
                  context,
                  text: "无法佩戴",
                ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: AppTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text(
        "装扮详情",
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
