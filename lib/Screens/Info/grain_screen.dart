import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/enums.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../l10n/l10n.dart';

class GrainScreen extends StatefulWidgetForNested {
  GrainScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'grain',
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

class _GrainScreenState extends BaseDynamicState<GrainScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<GrainScreen> {
  @override
  bool get wantKeepAlive => true;
  final List<GrainInfo> _grainList = [];
  bool _loading = false;
  int _total = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    super.initState();
    bindNestedRefreshSignal(() {
      _refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 140),
      );
    });
    if (widget.nested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onRefresh();
      });
    } else {
      _initPhase = InitPhase.successful;
      setState(() {});
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
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
            List<dynamic> t = value['data']['grains'];
            if (refresh) _grainList.clear();
            for (var e in t) {
              if (e != null) {
                _grainList.add(GrainInfo.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            _initPhase = InitPhase.successful;
            _noMore = t.isEmpty || _grainList.length >= _total;
            if (_noMore && !refresh) {
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load grain list", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
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
          ? ChewieTheme.getBackground(context)
          : Colors.transparent,
      appBar: widget.infoMode == InfoMode.me ? _buildAppBar() : null,
      body: _buildBody(),
    );
  }

  _buildBody() {
    switch (_initPhase) {
      case InitPhase.connecting:
        return const LoadingWidget(background: Colors.transparent);
      case InitPhase.failed:
        return CustomErrorWidget(
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return EasyRefresh.builder(
          header: widget.nested ? buildNestedRefreshHeader() : null,
          refreshOnStart: !widget.nested,
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoad: _noMore ? null : _onLoad,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _grainList.isNotEmpty
                ? _buildMainBody(physics)
                : EmptyPlaceholder(
                    text: appLocalizations.noGrain,
                    physics: physics,
                    shrinkWrap: false,
                  );
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildMainBody(ScrollPhysics physics) {
    return WaterfallFlow.extent(
      controller: widget.scrollController,
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
    );
  }

  _buildGrainRow(
    GrainInfo grain, {
    Function()? onTap,
    double verticalPadding = 12,
  }) {
    return ClickableGestureDetector(
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
                  child: ChewieItemBuilder.buildCachedImage(
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
                          "${grain.postCount}${appLocalizations.chapter} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(grain.updateTime)}",
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myGrains,
      actions: const [BlankIconButton()],
    );
  }
}
