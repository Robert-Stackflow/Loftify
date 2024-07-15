import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/dress_detail_screen.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/dress_api.dart';
import '../../Models/enums.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

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

class _DressScreenState extends State<DressScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<GiftData> _giftList = [];
  final List<GiftDress> _giftDressList = [];
  final List<GiftEmote> _giftEmoteList = [];
  bool _loading = false;
  int offset = 0;
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
  }

  _fetchList({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    return await DressApi.getDressList(
      offset: refresh ? 0 : offset,
      tag: widget.tag ?? "",
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
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
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
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
    return await _fetchList(refresh: true);
  }

  _onLoad() async {
    return await _fetchList();
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
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        childBuilder: (context, physics) {
          return _buildBody(physics);
        },
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return WaterfallFlow.builder(
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
    );
  }

  _buildGiftDressItem(GiftDress item) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
          context,
          DressDetailScreen(
            returnGiftDressId: item.returnGiftDressId,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.getCardBackground(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const SizedBox(width: 15),
            ItemBuilder.buildCachedImage(
              imageUrl: item.coverImg,
              context: context,
              showLoading: false,
              placeholderBackground: Colors.transparent,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "${item.partCount}个挂件",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 10),
            ItemBuilder.buildRoundButton(
              context,
              text: "查看详情",
              background: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 4),
          ],
        ),
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
      center: Utils.isNotEmpty(widget.tag) ? true : false,
      title: Utils.isNotEmpty(widget.tag)
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ItemBuilder.buildTagItem(
                context,
                widget.tag!,
                TagType.normal,
                shownTag: "#${widget.tag}#的相关装扮",
                backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                color: Theme.of(context).primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                showRightIcon: true,
                showTagLabel: false,
              ),
            )
          : Text(
              "装扮列表",
              style: Theme.of(context).textTheme.titleLarge,
            ),
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
      ],
    );
  }
}
