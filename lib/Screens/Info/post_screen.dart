import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/like_archive_util.dart';
import '../../Widgets/Design/loftify_state_view.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../Widgets/PostItem/loftify_post_archive_grid.dart';
import '../../l10n/l10n.dart';

class PostScreen extends StatefulWidgetForNested {
  PostScreen({
    super.key,
    this.infoMode = InfoMode.me,
    this.scrollController,
    this.blogId,
    this.blogName,
    super.nested = false,
    super.refreshListenable,
    super.refreshId = 'article',
  }) {
    if (infoMode == InfoMode.other) {
      assert(blogName != null);
    }
  }

  final InfoMode infoMode;
  final int? blogId;
  final String? blogName;
  final ScrollController? scrollController;

  static const String routeName = "/info/post";

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends BaseDynamicState<PostScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        NestedRefreshSignalMixin<PostScreen> {
  @override
  bool get wantKeepAlive => true;
  PostDetailData? _topPost;
  final List<PostDetailData> _postList = [];
  List<ArchiveData> _archiveDataList = [];
  bool _loading = false;
  bool _loadingRefresh = false;
  String? _loadingToken;
  String? _dataToken;
  int _requestEpoch = 0;
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

  Future<IndicatorResult> _fetchPosts({bool refresh = false}) async {
    if (!mounted) return IndicatorResult.none;
    final token = appProvider.token;
    if (_loading && _loadingToken == token && (!refresh || _loadingRefresh)) {
      return IndicatorResult.none;
    }
    if (_dataToken != null && _dataToken != token) {
      _postList.clear();
      _topPost = null;
      _archiveDataList = [];
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
    if (_postList.isEmpty && _topPost == null) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final blogInfo =
          widget.infoMode == InfoMode.me ? await HiveUtil.getUserInfo() : null;
      if (!isCurrentRequest()) return IndicatorResult.none;
      final blogName =
          widget.infoMode == InfoMode.me ? blogInfo?.blogName : widget.blogName;
      final blogId =
          widget.infoMode == InfoMode.me ? blogInfo?.blogId : widget.blogId;
      if (blogName == null ||
          blogName.isEmpty ||
          blogId == null ||
          blogId <= 0) {
        if (_postList.isEmpty && _topPost == null) {
          _initPhase = InitPhase.failed;
        }
        return IndicatorResult.fail;
      }
      final value = await UserApi.getPostList(
        blogName: blogName,
        blogId: blogId,
        offset: offset,
      );
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (value['meta']['status'] != 200) {
        if (_postList.isEmpty && _topPost == null) {
          _initPhase = InitPhase.failed;
        }
        IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        return IndicatorResult.fail;
      }
      final response = value['response'] as Map;
      final rawPosts = response['posts'] as List;
      final page = rawPosts
          .whereType<Map>()
          .map((item) =>
              PostDetailData.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.post != null)
          .toList();
      final posts = refresh ? <PostDetailData>[] : [..._postList];
      final seen = posts.map((item) => item.post!.id).toSet();
      for (final item in page) {
        if (seen.add(item.post!.id)) posts.add(item);
      }
      final rawTopPost = response['topPost'];
      final parsedTopPost = rawTopPost is Map
          ? PostDetailData.fromJson(Map<String, dynamic>.from(rawTopPost))
          : null;
      final topPost = parsedTopPost?.post != null
          ? parsedTopPost
          : refresh
              ? null
              : _topPost;
      final archives = response['archives'] == null
          ? refresh
              ? <ArchiveData>[]
              : _archiveDataList
          : buildLikeArchives(
              response['archives'],
              descriptionBuilder: appLocalizations.yearAndMonth,
            );
      _postList
        ..clear()
        ..addAll(posts);
      _topPost = topPost;
      _archiveDataList = archives;
      _nextOffset = offset + rawPosts.length;
      _noMore = rawPosts.isEmpty;
      _initPhase = InitPhase.successful;
      _dataToken = token;
      return !refresh && _noMore
          ? IndicatorResult.noMore
          : IndicatorResult.success;
    } catch (error, stackTrace) {
      if (!isCurrentRequest()) return IndicatorResult.none;
      if (_postList.isEmpty && _topPost == null) _initPhase = InitPhase.failed;
      ILogger.error('Failed to load post list', error, stackTrace);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (epoch == _requestEpoch && mounted) {
        setState(() {
          if (appProvider.token != token) {
            _postList.clear();
            _topPost = null;
            _archiveDataList = [];
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
    return await _fetchPosts(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
    return await _fetchPosts();
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
        return _postList.isNotEmpty || _topPost != null
            ? _buildNineGridGroup(physics)
            : EmptyPlaceholder(
                text: appLocalizations.noArticle,
                physics: physics,
                shrinkWrap: false,
              );
      },
    );
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    final posts = [..._postList];
    final archives = [
      for (final archive in _archiveDataList)
        ArchiveData(
          desc: archive.desc,
          count: archive.count,
          endTime: archive.endTime,
          startTime: archive.startTime,
        ),
    ];
    final slivers = <Widget>[];
    final top = _topPost;
    if (top?.post != null) {
      final repeatedIndex =
          posts.indexWhere((item) => item.post?.id == top!.post!.id);
      if (repeatedIndex >= 0) {
        final archive = likeArchiveForItemIndex(archives, repeatedIndex);
        if (archive != null) archive.count--;
        posts.removeAt(repeatedIndex);
      }
      slivers.add(SliverToBoxAdapter(
        child: ItemBuilder.buildTitle(
          context,
          title: appLocalizations.descriptionWithPostCount(
            appLocalizations.pin,
            '1',
          ),
          topMargin: 16,
          bottomMargin: 0,
        ),
      ));
      slivers.add(_buildNineGrid([top!], 0, 1));
    }
    var startIndex = 0;
    for (final archive in archives) {
      if (posts.length <= startIndex) break;
      if (archive.count <= 0) continue;
      final count = (posts.length - startIndex).clamp(0, archive.count);
      slivers.add(SliverToBoxAdapter(
        child: ItemBuilder.buildTitle(
          context,
          title: appLocalizations.descriptionWithPostCount(
            archive.desc,
            archive.count.toString(),
          ),
          topMargin: 16,
          bottomMargin: 0,
        ),
      ));
      slivers.add(_buildNineGrid(posts, startIndex, count));
      startIndex += archive.count;
    }
    if (startIndex < posts.length) {
      slivers.add(_buildNineGrid(posts, startIndex, posts.length - startIndex));
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
    return CustomScrollView(
      controller: widget.scrollController,
      physics: physics,
      slivers: slivers,
    );
  }

  Widget _buildNineGrid(List<PostDetailData> posts, int startIndex, int count) {
    return LoftifyPostArchiveSliverGrid(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      itemCount: count,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index, tileExtent) {
        final trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
          context,
          posts[trueIndex],
          wh: tileExtent,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myPosts,
    );
  }
}
