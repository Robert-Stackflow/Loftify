import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import 'nested_mixin.dart';

class GrainScreen extends StatefulWidgetForNested {
  GrainScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
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
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    super.initState();
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () => _onRefresh());
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  _fetchGrain({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _grainList.length;
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
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
            _initPhase = InitPhase.successful;
            if ((t.isEmpty || _grainList.length > _total) && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load grain list", e, t);
          if (mounted) IToast.showTop(S.current.loadFailed);
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
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return ItemBuilder.buildLoadingWidget(context,
            background: Colors.transparent);
      case InitPhase.failed:
        return ItemBuilder.buildErrorWidget(
          context: context,
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _grainList.isNotEmpty
                ? _buildMainBody(physics)
                : ItemBuilder.buildEmptyPlaceholder(
                    context: context,
                    text: S.current.noGrain,
                    physics: physics);
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildMainBody(ScrollPhysics physics) {
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: WaterfallFlow.extent(
        maxCrossAxisExtent: 560,
        physics: physics,
        padding: EdgeInsets.zero,
        children: List.generate(
          _grainList.length,
          (index) => _buildGrainRow(
            _grainList[index],
            verticalPadding: 8,
            onTap: () {
              RouteUtil.pushPanelCupertinoRoute(
                context,
                GrainDetailScreen(
                  grainId: _grainList[index].id,
                  blogId: _grainList[index].userId,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  _buildGrainRow(
    GrainInfo grain, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return ItemBuilder.buildClickable(
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
                            "${grain.postCount}${S.current.chapter} · ${S.current.updateAt}${Utils.formatTimestamp(grain.updateTime)}",
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
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      title: S.current.myGrains,
      actions: [ItemBuilder.buildBlankIconButton(context)],
    );
  }
}
