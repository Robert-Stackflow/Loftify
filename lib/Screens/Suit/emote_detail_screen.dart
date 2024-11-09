import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/dress_api.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/file_util.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class EmoteDetailScreen extends StatefulWidgetForNested {
  const EmoteDetailScreen({
    super.key,
    required this.emotePackId,
    super.nested = false,
  });

  final int emotePackId;

  static const String routeName = "/info/emoteDetail";

  @override
  State<EmoteDetailScreen> createState() => _EmoteDetailScreenState();
}

class _EmoteDetailScreenState extends State<EmoteDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GiftEmote? _giftEmote;
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
    currentAvatarImg =
        HiveUtil.getString(HiveUtil.customAvatarBoxKey, defaultValue: null);
    setState(() {});
  }

  _fetchDetail({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    userAvatarImg = (await HiveUtil.getUserInfo())?.bigAvaImg;
    await DressApi.getEmoteDetail(
      emotePackId: widget.emotePackId,
    ).then((value) {
      try {
        if (value['code'] != 200) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          _giftEmote = GiftEmote.fromJson(value['data']['returnGiftEmotePack']);
          _giftEmote!.emoteList
              .sort((a, b) => a.sizeType.compareTo(b.sizeType));
          if (mounted) setState(() {});
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load dress detail", e, t);
        if (mounted) IToast.showTop(S.current.loadFailed);
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
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _buildBody(physics);
          }),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return WaterfallFlow.builder(
      physics: physics,
      cacheExtent: 9999,
      padding: const EdgeInsets.all(10),
      itemCount: _giftEmote?.emoteList.length ?? 0,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        maxCrossAxisExtent: 300,
      ),
      itemBuilder: (context, index) {
        return _buildItem(_giftEmote!.emoteList[index]);
      },
    );
  }

  _buildItem(EmoteItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: MyTheme.getCardBackground(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ItemBuilder.buildHeroCachedImage(
            context: context,
            width: 90,
            height: 90,
            showLoading: false,
            placeholderBackground: Colors.transparent,
            imageUrl: item.url,
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            S.current.emote,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ItemBuilder.buildRoundButton(context,
                    text: S.current.download, onTap: () async {
                  CustomLoadingDialog.showLoading(title: S.current.downloading);
                  String url = item.url;
                  await FileUtil.saveImage(context, url);
                  CustomLoadingDialog.dismissLoading();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      title: S.current.emotePackageDetail,
    );
  }
}
