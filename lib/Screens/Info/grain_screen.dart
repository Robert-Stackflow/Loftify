import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/enums.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class GrainScreen extends StatefulWidget {
  GrainScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/grain";

  @override
  State<GrainScreen> createState() => _GrainScreenState();
}

class _GrainScreenState extends State<GrainScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<GrainInfo> _grainList = [];
  bool _loading = false;
  int _total = 0;
  int _offset = 0;
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
    if (widget.infoMode != InfoMode.me) {
      _onRefresh();
    }
  }

  _fetchGrain({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _grainList.length;
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      int blogId =
          widget.infoMode == InfoMode.me ? blogInfo!.blogId : widget.blogId!;
      return await UserApi.getGrainList(blogId: blogId, offset: offset)
          .then((value) {
        try {
          if (value['code'] != 0) {
            IToast.showTop(value['desc'] ?? value['msg']);
            return IndicatorResult.fail;
          } else {
            _total = value['data']['total'];
            _offset = value['data']['offset'];
            List<dynamic> t = value['data']['grains'];
            if (refresh) _grainList.clear();
            for (var e in t) {
              if (e != null) {
                _grainList.add(GrainInfo.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            if ((t.isEmpty || _grainList.length > _total) && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e) {
          if (mounted) IToast.showTop("加载失败");
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
          _loading = false;
        }
      });
    });
  }

  _onRefresh() async {
    return await _fetchGrain(refresh: true);
  }

  _onLoad() async {
    return await _fetchGrain();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: widget.infoMode == InfoMode.me
          ? MyTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
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
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: ListView.builder(
        physics: physics,
        padding: EdgeInsets.zero,
        itemCount: _grainList.length,
        itemBuilder: (context, index) {
          return _buildGrainRow(
            _grainList[index],
            verticalPadding: 8,
            onTap: () {
              RouteUtil.pushCupertinoRoute(
                context,
                GrainDetailScreen(
                  grainId: _grainList[index].id,
                  blogId: _grainList[index].userId,
                ),
              );
            },
          );
        },
      ),
    );
  }

  _buildGrainRow(
    GrainInfo grain, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return ItemBuilder.buildClickItem(
      GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          padding:
              EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ItemBuilder.buildCachedImage(
                      context: context,
                      imageUrl: grain.coverUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      showLoading: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            grain.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "${grain.postCount}篇 · 更新于${Utils.formatTimestamp(grain.updateTime)}",
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: 20,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...List.generate(
                                  grain.tags.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.only(right: 5),
                                    child: ItemBuilder.buildSmallTagItem(
                                      context,
                                      grain.tags[index],
                                      showIcon: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: MyTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text("我的粮单", style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ItemBuilder.buildBlankIconButton(context),
        const SizedBox(width: 5),
        // ItemBuilder.buildIconButton(
        //     context: context,
        //     icon: Icon(Icons.more_vert_rounded,
        //         color: Theme.of(context).iconTheme.color),
        //     onTap: () {}),
        // const SizedBox(width: 5),
      ],
    );
  }
}
