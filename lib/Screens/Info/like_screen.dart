import 'dart:math' as math;

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/enums.dart';
import '../../Utils/like_archive_util.dart';
import '../../Utils/paged_data_controller.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../l10n/l10n.dart';

class LikeScreen extends StatefulWidgetForNested {
  LikeScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'like',
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/like";

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends BaseDynamicState<LikeScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<LikeScreen> {
  @override
  bool get wantKeepAlive => true;
  final EasyRefreshController _refreshController = EasyRefreshController();
  late final PagedDataController<PostDetailData, int, int, List<ArchiveData>>
      _pagingController;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  List<PostDetailData> get _likeList => _pagingController.items;
  List<ArchiveData> get _archiveDataList =>
      _pagingController.metadata ?? const <ArchiveData>[];

  @override
  void initState() {
    super.initState();
    bindNestedRefreshSignal(() {
      _refreshController.callRefresh(
        overOffset: 28,
        duration: const Duration(milliseconds: 140),
      );
    });
    _pagingController = PagedDataController(
      initialCursor: 0,
      keyOf: (item) =>
          item.post?.id ?? item.postData?.id ?? identityHashCode(item),
      loader: _loadLikePage,
      onError: (error, stackTrace) {
        ILogger.error('Failed to load like list', error, stackTrace);
        if (!mounted) return;
        IToast.showTop(
          error is PagedDataException && StringUtil.isNotEmpty(error.message)
              ? error.message
              : appLocalizations.loadFailed,
        );
      },
    )..addListener(_handlePagingChanged);
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
    _pagingController
      ..removeListener(_handlePagingChanged)
      ..dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<PagedDataPage<PostDetailData, int, List<ArchiveData>>> _loadLikePage(
      int cursor, bool refresh) async {
    final blogInfo = await HiveUtil.getUserInfo();
    final blogName =
        widget.infoMode == InfoMode.me ? blogInfo?.blogName : widget.blogName;
    if (StringUtil.isEmpty(blogName)) {
      throw const PagedDataException('');
    }

    final offset = refresh ? 0 : cursor;
    final value = await UserApi.getLikeList(
      blogName: blogName!,
      offset: offset,
    );
    final meta = value['meta'];
    final status = meta is Map ? (meta['status'] as num?)?.toInt() : null;
    if (status != 200) {
      final message = meta is Map ? meta['desc'] ?? meta['msg'] : null;
      throw PagedDataException(message?.toString() ?? '');
    }

    final response = value['response'];
    if (response is! Map) throw const PagedDataException('');
    final total = (response['count'] as num?)?.toInt() ?? 0;
    final archives = _parseArchives(response['archives']);
    final rawItems = response['items'] is List
        ? List<dynamic>.from(response['items'] as List)
        : const <dynamic>[];
    final items = <PostDetailData>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      try {
        items.add(PostDetailData.fromJson(
          Map<String, dynamic>.from(rawItem),
        ));
      } catch (error, stackTrace) {
        ILogger.error('Skipped malformed liked card', error, stackTrace);
      }
    }
    final nextOffset = offset + rawItems.length;
    return PagedDataPage(
      items: items,
      nextCursor: nextOffset,
      hasMore: rawItems.isNotEmpty && nextOffset < total,
      total: total,
      metadata: archives,
    );
  }

  List<ArchiveData> _parseArchives(dynamic rawArchives) {
    return buildLikeArchives(
      rawArchives,
      descriptionBuilder: (month, year) =>
          appLocalizations.yearAndMonth(month, year),
      onMalformed: (error, stackTrace) {
        ILogger.error('Skipped malformed like archive', error, stackTrace);
      },
    );
  }

  void _handlePagingChanged() {
    if (mounted) setState(() {});
  }

  Future<IndicatorResult> _onRefresh() async {
    final wasEmpty = _likeList.isEmpty;
    if (wasEmpty && _initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      if (mounted) setState(() {});
    }
    final result = await _pagingController.refresh();
    if (!mounted) return result;
    _initPhase = result == IndicatorResult.fail && _likeList.isEmpty
        ? InitPhase.failed
        : InitPhase.successful;
    setState(() {});
    return result;
  }

  Future<IndicatorResult> _onLoad() => _pagingController.load();

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
        return Stack(
          children: [
            EasyRefresh.builder(
              header: widget.nested ? buildNestedRefreshHeader() : null,
              refreshOnStart: !widget.nested,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _pagingController.noMore ? null : _onLoad,
              triggerAxis: Axis.vertical,
              childBuilder: (context, physics) {
                return _likeList.isNotEmpty
                    ? _buildNineGridGroup(physics)
                    : EmptyPlaceholder(
                        text: appLocalizations.noLike,
                        physics: physics,
                        shrinkWrap: false,
                      );
              },
            ),
            Positioned(
              right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
              bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
              child: _buildFloatingButtons(),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    final slivers = <Widget>[];
    var startIndex = 0;

    void addGroup({required String description, required int groupCount}) {
      if (groupCount <= 0 || startIndex >= _likeList.length) return;
      final visibleCount = math.min(groupCount, _likeList.length - startIndex);
      final groupStartIndex = startIndex;
      slivers.add(
        SliverToBoxAdapter(
          child: ItemBuilder.buildTitle(
            context,
            title: appLocalizations.descriptionWithPostCount(
              description,
              groupCount.toString(),
            ),
            topMargin: 16,
            bottomMargin: 0,
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final trueIndex = groupStartIndex + index;
                final item = _likeList[trueIndex];
                final postId = item.post?.id ?? item.postData?.id;
                return CommonInfoItemBuilder.buildNineGridPostItem(
                  context,
                  item,
                  key: postId == null || postId == 0
                      ? ObjectKey(item)
                      : ValueKey('liked-$postId'),
                  wh: 160,
                  onLikeChanged: (liked) {
                    if (!liked) _removeLikedPost(item);
                  },
                );
              },
              childCount: visibleCount,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: true,
            ),
          ),
        ),
      );
      startIndex += groupCount;
    }

    for (final archive in _archiveDataList) {
      addGroup(description: archive.desc, groupCount: archive.count);
    }
    if (startIndex < _likeList.length) {
      addGroup(
        description: appLocalizations.myLikes,
        groupCount: _likeList.length - startIndex,
      );
    }
    slivers.add(
      const SliverToBoxAdapter(child: SizedBox(height: 20)),
    );

    return CustomScrollView(
      key: PageStorageKey('likes-${widget.blogName ?? 'me'}'),
      controller: widget.scrollController,
      physics: physics,
      slivers: slivers,
    );
  }

  void _removeLikedPost(PostDetailData target) {
    _removeLocalItems(Set<PostDetailData>.identity()..add(target));
  }

  void _removeLocalItems(Set<PostDetailData> targets) {
    if (targets.isEmpty) return;
    final removedIndices = <int>[];
    for (var index = 0; index < _likeList.length; index++) {
      if (!targets.contains(_likeList[index])) continue;
      removedIndices.add(index);
    }
    decrementLikeArchives(_archiveDataList, removedIndices);
    _pagingController.removeWhere(
      targets.contains,
      updateCursor: (cursor, removedCount) =>
          math.max(0, cursor - removedCount),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myLikes,
      actions: [
        CircleIconButton(
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
            }),
      ],
    );
  }

  _buildMoreButtons() {
    return FlutterContextMenu(
      entries: [
        FlutterContextMenuItem(
          appLocalizations.clearInvalidContent,
          iconData: Icons.delete_outline_rounded,
          onPressed: () async {
            try {
              final value = await UserApi.deleteInvalidLike(
                blogId: await HiveUtil.getUserId(),
              );
              if (!mounted) return;
              if (value['meta']['status'] != 200) {
                IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              } else {
                final invalidItems = Set<PostDetailData>.identity()
                  ..addAll(
                    _likeList.where(CommonInfoItemBuilder.isInvalid),
                  );
                _removeLocalItems(invalidItems);
                IToast.showTop(appLocalizations.clearSuccess);
              }
            } catch (error, stackTrace) {
              ILogger.error('Failed to clear invalid likes', error, stackTrace);
              if (mounted) IToast.showTop(appLocalizations.loadFailed);
            }
          },
        ),
      ],
    );
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onTap: () {
                  BottomSheetBuilder.showContextMenu(
                      context, _buildMoreButtons());
                },
              ),
            ],
          )
        : emptyWidget;
  }
}
