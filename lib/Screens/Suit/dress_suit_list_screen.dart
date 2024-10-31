import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/gift_api.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Models/dress_response.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class DressSuitListScreen extends StatefulWidget {
  const DressSuitListScreen({super.key});

  static const String routeName = "/info/dressSuit";

  @override
  State<DressSuitListScreen> createState() => DressSuitListScreenState();
}

class DressSuitListScreenState extends State<DressSuitListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<DressingItem> _dressSuitList = [];
  bool _loading = false;
  int offset = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;

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
    return EasyRefresh.builder(
      refreshOnStart: true,
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
    return ItemBuilder.buildLoadMoreNotification(
      child: WaterfallFlow.builder(
        physics: physics,
        cacheExtent: 9999,
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
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: () {},
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ItemBuilder.buildCachedImage(
                imageUrl: item.img,
                context: context,
                height: 400,
                fit: BoxFit.cover,
                width: double.infinity,
                showLoading: false,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.intro,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 10),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: ItemBuilder.buildRoundButton(
                  //         context,
                  //         background: Colors.white24,
                  //         color: Colors.white,
                  //         text: "查看详情",
                  //         onTap: () {},
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
