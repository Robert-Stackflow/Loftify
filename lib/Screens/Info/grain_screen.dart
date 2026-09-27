import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Widgets/Design/loftify_state_view.dart';
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
  bool _loadingRefresh = false;
  String? _loadingToken;
  String? _dataToken;
  int _requestEpoch = 0;
  int _total = 0;
  int _nextOffset = 0;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.connecting;

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
    }
  }

  @override
  void dispose() {
    unbindNestedRefreshSignal();
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchGrain({bool refresh = false}) async {
    if (!mounted) return IndicatorResult.none;
    final token = appProvider.token;
    if (_loading && _loadingToken == token && (!refresh || _loadingRefresh)) {
      return IndicatorResult.none;
    }
    if (_dataToken != null && _dataToken != token) {
      _grainList.clear();
      _total = 0;
      _nextOffset = 0;
      _noMore = false;
      _initPhase = InitPhase.connecting;
    }
    final epoch = ++_requestEpoch;
    bool isCurrentRequest() =>
        mounted && appProvider.token == token && epoch == _requestEpoch;
    _loading = true;
    _loadingRefresh = refresh;
    _loadingToken = token;
    final offset = refresh ? 0 : _nextOffset;
    if (_grainList.isEmpty) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final blogInfo =
          widget.infoMode == InfoMode.me ? await HiveUtil.getUserInfo() : null;
      if (!isCurrentRequest()) return IndicatorResult.none;
      final blogId =
          widget.infoMode == InfoMode.me ? blogInfo?.blogId : widget.blogId;
      if (blogId == null || blogId <= 0) {
        if (_grainList.isEmpty) _initPhase = InitPhase.failed;
        return IndicatorResult.fail;
      }
      final value = await UserApi.getGrainList(blogId: blogId, offset: offset);
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (value['code'] != 0) {
        if (_grainList.isEmpty) _initPhase = InitPhase.failed;
        IToast.showTop(value['desc'] ?? value['msg']);
        return IndicatorResult.fail;
      }
      final data = value['data'] as Map;
      final total = (data['total'] as num).toInt();
      final rawItems = data['grains'] as List;
      final page = rawItems
          .whereType<Map>()
          .map((item) => GrainInfo.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final grains = refresh ? <GrainInfo>[] : [..._grainList];
      final seen = grains.map((grain) => grain.id).toSet();
      for (final grain in page) {
        if (seen.add(grain.id)) grains.add(grain);
      }
      _grainList
        ..clear()
        ..addAll(grains);
      _total = total;
      _nextOffset = offset + rawItems.length;
      _noMore = rawItems.isEmpty || _nextOffset >= _total;
      _initPhase = InitPhase.successful;
      _dataToken = token;
      return !refresh && _noMore
          ? IndicatorResult.noMore
          : IndicatorResult.success;
    } catch (error, stackTrace) {
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (_grainList.isEmpty) _initPhase = InitPhase.failed;
      ILogger.error('Failed to load grain list', error, stackTrace);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (epoch == _requestEpoch && mounted) {
        setState(() {
          if (appProvider.token != token) {
            _grainList.clear();
            _total = 0;
            _nextOffset = 0;
            _noMore = false;
            _initPhase = InitPhase.failed;
            _dataToken = null;
          }
        });
      }
      if (epoch == _requestEpoch) {
        _loading = false;
        _loadingRefresh = false;
        _loadingToken = null;
      }
    }
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchGrain(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
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

  Widget _buildBody() {
    return EasyRefresh.builder(
      header: widget.nested ? buildNestedRefreshHeader() : null,
      refreshOnStart: !widget.nested,
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _noMore ? null : _onLoad,
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) {
        if (_initPhase != InitPhase.successful) {
          final loading = _initPhase == InitPhase.connecting;
          return CustomScrollView(
            controller: widget.scrollController,
            physics: physics,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: LoftifyStateView(
                  visual: loading
                      ? LoftifyStateVisual.loading
                      : LoftifyStateVisual.error,
                  title: loading
                      ? appLocalizations.loading
                      : appLocalizations.loadFailed,
                  scrollWhenConstrained: false,
                  actionLabel: loading ? null : chewieLocalizations.retry,
                  onAction:
                      loading ? null : () => _refreshController.callRefresh(),
                ),
              ),
            ],
          );
        }
        return _grainList.isNotEmpty
            ? _buildMainBody(physics)
            : EmptyPlaceholder(
                text: appLocalizations.noGrain,
                physics: physics,
                shrinkWrap: false,
              );
      },
    );
  }

  Widget _buildMainBody(ScrollPhysics physics) {
    return WaterfallFlow.builder(
      controller: widget.scrollController,
      physics: physics,
      cacheExtent: MediaQuery.sizeOf(context).height,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _grainList.length,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
      ),
      itemBuilder: (context, index) {
        final grain = _grainList[index];
        return _buildGrainRow(
          grain,
          verticalPadding: 8,
          onTap: () {
            RouteUtil.pushPanelCupertinoRoute(
              context,
              GrainDetailScreen(
                grainId: grain.id,
                blogId: grain.userId,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrainRow(
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grain.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${grain.postCount}${appLocalizations.chapter} · ${appLocalizations.updateAt}${TimeUtil.formatTimestamp(grain.updateTime)}",
                          style: Theme.of(context).textTheme.labelMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (grain.tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final tag in grain.tags)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: ItemBuilder.buildSmallTagItem(
                                      context,
                                      tag,
                                      showIcon: false,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
