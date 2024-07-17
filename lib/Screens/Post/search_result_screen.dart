import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/search_api.dart';
import 'package:loftify/Models/collection_response.dart';
import 'package:loftify/Models/enums.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:loftify/Models/search_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/grain_detail_screen.dart';
import 'package:loftify/Screens/Post/tag_detail_screen.dart';
import 'package:loftify/Utils/iprint.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/PostItem/search_post_flow_item_builder.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Api/post_api.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Custom/custom_tab_indicator.dart';
import '../../Widgets/Custom/sliver_appbar_delegate.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/recommend_flow_item_builder.dart';
import 'collection_detail_screen.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key, required this.searchKey});

  static const String routeName = "/search/result";

  final String searchKey;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<SearchSuggestItem> _sugList = [];
  SearchAllResult? _allResult;
  TagInfo? _tagRank;
  int _currentTabIndex = 0;
  final List<Collection> _collectionList = [];
  final List<SearchPost> _postList = [];
  final List<GrainInfo> _grainList = [];
  final List<SearchBlogData> _userList = [];
  late TabController _tabController;
  final List<TagInfo> _tagList = [];
  final ScrollController _scrollController = ScrollController();
  TextEditingController? _searchController;
  final EasyRefreshController _allResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _tagResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _collectionResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _postResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _grainResultRefreshController =
      EasyRefreshController();
  final EasyRefreshController _userResultRefreshController =
      EasyRefreshController();
  final ScrollController _allResultScrollController = ScrollController();
  final ScrollController _tagResultScrollController = ScrollController();
  final ScrollController _collectionResultScrollController = ScrollController();
  final ScrollController _postResultScrollController = ScrollController();
  final ScrollController _grainResultScrollController = ScrollController();
  final ScrollController _userResultScrollController = ScrollController();

  final List<String> _tabLabelList = ["综合", "标签", "合集", "粮单", "文章", "用户"];
  int _allResultOffset = 0;
  int _tagResultOffset = 0;
  int _collectionResultOffset = 0;
  int _postResultOffset = 0;
  int _grainResultOffset = 0;
  int _userResultOffset = 0;
  bool _allResultLoading = false;
  bool _collectionResultLoading = false;
  bool _tagResultLoading = false;
  bool _postResultLoading = false;
  bool _grainResultLoading = false;
  bool _userResultLoading = false;
  bool _allPostResultLoading = false;
  bool _tagResultNoMore = false;
  bool _collectionResultNoMore = false;
  bool _postResultNoMore = false;
  bool _grainResultNoMore = false;
  bool _userResultNoMore = false;

  @override
  void initState() {
    super.initState();
    _performSearch(widget.searchKey, init: true);
    initTab();
    initScrollController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildMainBody(),
                  if (_sugList.isNotEmpty) _buildSuggestList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  initTab() {
    _tabController = TabController(length: _tabLabelList.length, vsync: this);
    _tabController.animation?.addListener(() {
      int indexChange =
          _tabController.offset.abs() > 0.8 ? _tabController.offset.round() : 0;
      int index = _tabController.index + indexChange;
      if (index != _currentTabIndex) {
        setState(() => _currentTabIndex = index);
      }
    });
  }

  initScrollController() {
    _allResultScrollController.addListener(() {
      if (_allResultScrollController.position.pixels >
          _allResultScrollController.position.maxScrollExtent -
              kLoadExtentOffset) {
        _fetchAllPostResult();
      }
    });
    _tagResultScrollController.addListener(() {
      if (!_tagResultNoMore &&
          _tagResultScrollController.position.pixels >
              _tagResultScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchTagResult();
      }
    });
    _collectionResultScrollController.addListener(() {
      if (!_collectionResultNoMore &&
          _collectionResultScrollController.position.pixels >
              _collectionResultScrollController.position.maxScrollExtent -
                  200) {
        _fetchCollectionResult();
      }
    });
    _postResultScrollController.addListener(() {
      if (!_postResultNoMore &&
          _postResultScrollController.position.pixels >
              _postResultScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchPostResult();
      }
    });
    _grainResultScrollController.addListener(() {
      if (!_grainResultNoMore &&
          _grainResultScrollController.position.pixels >
              _grainResultScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchGrainResult();
      }
    });
    _userResultScrollController.addListener(() {
      if (!_userResultNoMore &&
          _userResultScrollController.position.pixels >
              _userResultScrollController.position.maxScrollExtent -
                  kLoadExtentOffset) {
        _fetchUserResult();
      }
    });
  }

  _bindSuggest() {
    if (_searchController!.text.isEmpty) {
      _sugList.clear();
      if (mounted) setState(() {});
    } else {
      _performSuggest(_searchController!.text);
    }
  }

  _fetchAllResult() async {
    if (_allResultLoading) return;
    _allResultLoading = true;
    return await SearchApi.getAllSearchResult(key: _searchController!.text)
        .then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          if (value['data'] != null) {
            _allResult = SearchAllResult.fromJson(value['data']);
            _allResultOffset = _allResult!.offset;
          }
          if (mounted) setState(() {});
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        _allResultLoading = false;
      }
    });
  }

  _fetchAllPostResult() async {
    if (_allPostResultLoading) return;
    _allPostResultLoading = true;
    return await SearchApi.getAllSearchPostResult(
      key: _searchController!.text,
      offset: _allResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          if (value['data'] != null) {
            var tmp = SearchAllResult.fromJson(value['data']);
            _allResultOffset = tmp.offset;
            _allResult?.posts.addAll(tmp.posts);
          }
          if (mounted) setState(() {});
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _allPostResultLoading = false;
      }
    });
  }

  _fetchTagResult({bool refresh = false}) async {
    if (_tagResultLoading) return;
    if (refresh) _tagResultNoMore = false;
    _tagResultLoading = true;
    return await SearchApi.getTagSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : _tagResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<TagInfo> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _tagResultOffset = value['data']['offset'];
            }
            if (value['data']['tagRank'] != null) {
              _tagRank = TagInfo.fromJson(value['data']['tagRank']);
            }
            if (value['data']['tags'] != null) {
              tmp = (value['data']['tags'] as List)
                  .map((e) => TagInfo.fromJson(e))
                  .toList();
              if (refresh) _tagList.clear();
              for (var exist in _tagList) {
                tmp.removeWhere((element) => element.tagName == exist.tagName);
              }
              _tagList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _tagResultNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _tagResultLoading = false;
      }
    });
  }

  _fetchCollectionResult({bool refresh = false}) async {
    if (_collectionResultLoading) return;
    if (refresh) _collectionResultNoMore = false;
    _collectionResultLoading = true;
    return await SearchApi.getCollectionSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : _collectionResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<Collection> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _collectionResultOffset = value['data']['offset'];
            }
            if (value['data']['collections'] != null) {
              tmp = (value['data']['collections'] as List)
                  .map((e) => Collection.fromJson(e))
                  .toList();
              if (refresh) _collectionList.clear();
              for (var exist in _collectionList) {
                tmp.removeWhere((element) => element.id == exist.id);
              }
              _collectionList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _collectionResultNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _collectionResultLoading = false;
      }
    });
  }

  _fetchPostResult({bool refresh = false}) async {
    if (_postResultLoading) return;
    if (refresh) _postResultNoMore = false;
    _postResultLoading = true;
    return await SearchApi.getPostSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : _postResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<SearchPost> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _postResultOffset = value['data']['offset'];
            }
            if (value['data']['posts'] != null) {
              tmp = (value['data']['posts'] as List)
                  .map((e) => SearchPost.fromJson(e))
                  .toList();
              if (refresh) _postList.clear();
              for (var exist in _postList) {
                tmp.removeWhere((element) => element.id == exist.id);
              }
              _postList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _postResultNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _postResultLoading = false;
      }
    });
  }

  _fetchGrainResult({bool refresh = false}) async {
    if (_grainResultLoading) return;
    if (refresh) _grainResultNoMore = false;
    _grainResultLoading = true;
    return await SearchApi.getGrainSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : _grainResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<GrainInfo> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _grainResultOffset = value['data']['offset'];
            }
            if (value['data']['grainList'] != null) {
              tmp = (value['data']['grainList'] as List)
                  .map((e) => GrainInfo.fromJson(e))
                  .toList();
              if (refresh) _grainList.clear();
              for (var exist in _grainList) {
                tmp.removeWhere((element) => element.id == exist.id);
              }
              _grainList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _grainResultNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _grainResultLoading = false;
      }
    });
  }

  _fetchUserResult({bool refresh = false}) async {
    if (_userResultLoading) return;
    if (refresh) _userResultNoMore = false;
    _userResultLoading = true;
    return await SearchApi.getUserSearchResult(
      key: _searchController!.text,
      offset: refresh ? 0 : _userResultOffset,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
        } else {
          List<SearchBlogData> tmp = [];
          if (value['data'] != null) {
            if (value['data']['offset'] != null) {
              _userResultOffset = value['data']['offset'];
            }
            if (value['data']['blogs'] != null) {
              tmp = (value['data']['blogs'] as List)
                  .map((e) => SearchBlogData.fromJson(e))
                  .toList();
              if (refresh) _userList.clear();
              for (var exist in _userList) {
                tmp.removeWhere((element) =>
                    element.blogInfo.blogId == exist.blogInfo.blogId);
              }
              _userList.addAll(tmp);
            }
          }
          if (mounted) setState(() {});
          if (tmp.isEmpty) {
            _userResultNoMore = true;
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (_) {
        IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _userResultLoading = false;
      }
    });
  }

  _performSearch(String str, {bool init = false}) async {
    bool processed = await UriUtil.processUrl(context, str, quiet: true);
    if (!processed) {
      _searchController = TextEditingController(text: str);
      _sugList.clear();
      _userList.clear();
      _postList.clear();
      _tagList.clear();
      _collectionList.clear();
      _grainList.clear();
      Utils.addSearchHistory(str);
      _fetchAllResult();
      _fetchCollectionResult(refresh: true);
      _fetchGrainResult(refresh: true);
      _fetchPostResult(refresh: true);
      _fetchTagResult(refresh: true);
      _fetchUserResult(refresh: true);
      if (!init) {
        FocusScope.of(context).requestFocus(FocusNode());
        _tabController.animateTo(0);
      }
      _searchController!.addListener(_bindSuggest);
    }
  }

  _jumpToTag(String tag) {
    RouteUtil.pushCupertinoRoute(context, TagDetailScreen(tag: tag));
  }

  _performSuggest(String str) {
    SearchApi.getSuggestList(key: str).then((value) {
      if (value['code'] != 0) {
        IToast.showTop(context, text: value['msg']);
      } else {
        if (value['data']['items'] != null &&
            _searchController!.text.isNotEmpty) {
          _sugList = (value['data']['items'] as List)
              .map((e) => SearchSuggestItem.fromJson(e))
              .toList();
        }
        if (mounted) setState(() {});
      }
    });
  }

  _buildSuggestList() {
    return Container(
      color: AppTheme.getBackground(context),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        itemCount: _sugList.length,
        itemBuilder: (context, index) {
          return _buildSuggestItem(index, _sugList[index]);
        },
      ),
    );
  }

  _buildSuggestItem(int index, SearchSuggestItem item) {
    switch (item.type) {
      case 0:
        if (index == 0) {
          return ItemBuilder.buildRankTagRow(context, item.tagInfo!, onTap: () {
            Utils.addSearchHistory(_searchController!.text);
            _jumpToTag(item.tagInfo!.tagName);
          });
        } else {
          return ItemBuilder.buildTagRow(context, item.tagInfo!, onTap: () {
            Utils.addSearchHistory(_searchController!.text);
            _jumpToTag(item.tagInfo!.tagName);
          });
        }
      case 1:
        return ItemBuilder.buildTagRow(context, item.tagInfo!, onTap: () {
          Utils.addSearchHistory(_searchController!.text);
          _performSearch(item.tagInfo!.tagName);
        });
      case 2:
        return ItemBuilder.buildUserRow(context, item.blogData!, onTap: () {
          Utils.addSearchHistory(_searchController!.text);
          RouteUtil.pushCupertinoRoute(
            context,
            UserDetailScreen(
              blogId: item.blogData!.blogInfo.blogId,
              blogName: item.blogData!.blogInfo.blogName,
            ),
          );
        });
      default:
        return Container();
    }
  }

  _buildMainBody() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_tabLabelList.isNotEmpty)
          SliverPersistentHeader(
            key: ValueKey(Utils.getRandomString()),
            pinned: true,
            delegate: SliverAppBarDelegate(
              radius: 0,
              background: AppTheme.getBackground(context),
              tabBar: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                controller: _tabController,
                tabs: _tabLabelList
                    .asMap()
                    .entries
                    .map((entry) => ItemBuilder.buildAnimatedTab(context,
                        selected: entry.key == _currentTabIndex,
                        text: entry.value))
                    .toList(),
                labelPadding: const EdgeInsets.symmetric(horizontal: 0),
                enableFeedback: true,
                dividerHeight: 0,
                physics: const BouncingScrollPhysics(),
                labelStyle: Theme.of(context).textTheme.titleLarge,
                unselectedLabelStyle: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.apply(color: Colors.grey),
                indicator: CustomTabIndicator(
                  borderColor: Theme.of(context).primaryColor,
                ),
                onTap: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                  // switch (index) {
                  //   case 0:
                  //     _allResultRefreshController.callRefresh();
                  //     break;
                  //   case 1:
                  //     _tagResultRefreshController.callRefresh();
                  //     break;
                  //   case 2:
                  //     _collectionResultRefreshController.callRefresh();
                  //     break;
                  //   case 3:
                  //     _grainResultRefreshController.callRefresh();
                  //     break;
                  //   case 4:
                  //     _postResultRefreshController.callRefresh();
                  //     break;
                  //   case 5:
                  //     _userResultRefreshController.callRefresh();
                  //     break;
                  // }
                },
              ),
            ),
          ),
        if (_tabLabelList.isNotEmpty)
          SliverFillRemaining(
            child: _buildTabView(),
          ),
      ],
    );
  }

  Widget _buildTabView() {
    List<Widget> children = [];
    children.add(_buildAllResultTab());
    children.add(_buildTagResultTab());
    children.add(_buildCollectionResultTab());
    children.add(_buildGrainResultTab());
    children.add(_buildPostResultTab());
    children.add(_buildUserResultTab());
    return TabBarView(
      controller: _tabController,
      children: children,
    );
  }

  _buildDivider() {
    return Container(height: 3, color: Theme.of(context).dividerColor);
  }

  Widget _buildAllResultTab() {
    return EasyRefresh.builder(
      controller: _allResultRefreshController,
      onRefresh: () async {
        return await _fetchAllResult();
      },
      onLoad: () async {
        return await _fetchAllPostResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => _allResult != null
          ? CustomScrollView(
              physics: physics,
              controller: _allResultScrollController,
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const SizedBox(height: 10),
                      if (_allResult!.tags.isEmpty &&
                          _allResult!.tagRank == null &&
                          _allResult!.posts.isEmpty)
                        Container(
                          height: 160,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: ItemBuilder.buildEmptyPlaceholder(
                            context: context,
                            text: "暂无结果",
                          ),
                        ),
                      if (_allResult!.tagRank != null)
                        ItemBuilder.buildRankTagRow(
                          context,
                          _allResult!.tagRank!,
                          useBackground: false,
                          onTap: () {
                            _jumpToTag(_allResult!.tagRank!.tagName);
                          },
                        ),
                      if (_allResult!.tagRank != null) _buildDivider(),
                      if (_allResult!.tags.isNotEmpty)
                        ItemBuilder.buildTitle(
                          context,
                          title: "相关标签",
                          suffixText: "查看全部",
                          topMargin: 16,
                          bottomMargin: 8,
                          onTap: () {
                            _tabController.animateTo(1);
                          },
                        ),
                      if (_allResult!.tags.isNotEmpty)
                        ...List<Widget>.generate(
                            min(_allResult!.tags.length, 2), (index) {
                          return ItemBuilder.buildTagRow(
                            context,
                            _allResult!.tags[index],
                            verticalPadding: 8,
                            onTap: () {
                              if (_allResult!.tags[index].joinCount != -1) {
                                _jumpToTag(_allResult!.tags[index].tagName);
                              } else {
                                _performSearch(_allResult!.tags[index].tagName);
                              }
                            },
                          );
                        }),
                      if (_allResult!.tags.isNotEmpty)
                        const SizedBox(height: 8),
                      if (_allResult!.tags.isNotEmpty) _buildDivider(),
                      if (_allResult!.posts.isNotEmpty)
                        ItemBuilder.buildTitle(
                          context,
                          title: "相关文章",
                          suffixText: "查看全部",
                          topMargin: 16,
                          bottomMargin: 8,
                          onTap: () {
                            _tabController.animateTo(4);
                          },
                        ),
                    ],
                  ),
                ),
                if (_allResult!.posts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                    sliver: SliverWaterfallFlow(
                      gridDelegate:
                          const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        maxCrossAxisExtent: 300,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return GestureDetector(
                            child: RecommendFlowItemBuilder
                                .buildWaterfallFlowPostItem(
                                    context, _allResult!.posts[index],
                                    onLikeTap: () async {
                              var item = _allResult!.posts[index];
                              HapticFeedback.mediumImpact();
                              IPrint.debug(item.toJson());
                              return await PostApi.likeOrUnLike(
                                      isLike: !item.favorite,
                                      postId: item.itemId,
                                      blogId: item.postData!.postView.blogId)
                                  .then((value) {
                                setState(() {
                                  if (value['meta']['status'] != 200) {
                                    IToast.showTop(context,
                                        text: value['meta']['desc'] ??
                                            value['meta']['msg']);
                                  } else {
                                    item.favorite = !item.favorite;
                                    if (item.postData!.postCount != null) {
                                      item.postData!.postCount!.favoriteCount +=
                                          item.favorite ? 1 : -1;
                                    }
                                  }
                                });
                                return value['meta']['status'];
                              });
                            }),
                          );
                        },
                        childCount: _allResult!.posts.length,
                      ),
                    ),
                  ),
              ],
            )
          : ItemBuilder.buildLoadingDialog(
              context,
              background: AppTheme.getBackground(context),
            ),
    );
  }

  Widget _buildTagResultTab() {
    return EasyRefresh.builder(
      controller: _tagResultRefreshController,
      onRefresh: () async {
        return await _fetchTagResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchTagResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        controller: _tagResultScrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_tagList.isEmpty && _tagRank == null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无标签",
                    ),
                  ),
                if (_tagRank != null)
                  ItemBuilder.buildRankTagRow(
                    context,
                    _tagRank!,
                    useBackground: false,
                    onTap: () {
                      _jumpToTag(_tagRank!.tagName);
                    },
                  ),
                if (_tagRank != null && _tagList.isNotEmpty) _buildDivider(),
                if (_tagList.isNotEmpty)
                  ...List<Widget>.generate(_tagList.length, (index) {
                    return ItemBuilder.buildTagRow(
                      context,
                      _tagList[index],
                      verticalPadding: 8,
                      onTap: () {
                        if (_tagList[index].joinCount != -1) {
                          _jumpToTag(_tagList[index].tagName);
                        } else {
                          _performSearch(_tagList[index].tagName);
                        }
                      },
                    );
                  }),
                if (_tagList.isNotEmpty) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionResultTab() {
    return EasyRefresh.builder(
      controller: _collectionResultRefreshController,
      onRefresh: () async {
        return await _fetchCollectionResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchCollectionResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        controller: _collectionResultScrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_collectionList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无合集",
                    ),
                  ),
              ],
            ),
          ),
          SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 0,
              crossAxisSpacing: 6,
              maxCrossAxisExtent: 600,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ItemBuilder.buildCollectionRow(
                    context, _collectionList[index], verticalPadding: 8,
                    onTap: () {
                  RouteUtil.pushCupertinoRoute(
                    context,
                    CollectionDetailScreen(
                      collectionId: _collectionList[index].id,
                      blogId: _collectionList[index].blogId,
                      blogName: _collectionList[index].blogName,
                      postId: 0,
                    ),
                  );
                });
              },
              childCount: _collectionList.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostResultTab() {
    return EasyRefresh.builder(
      controller: _postResultRefreshController,
      onRefresh: () async {
        return await _fetchPostResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchPostResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        controller: _postResultScrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_postList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无文章",
                    ),
                  ),
              ],
            ),
          ),
          if (_postList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
              sliver: SliverWaterfallFlow(
                gridDelegate:
                    const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  maxCrossAxisExtent: 300,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return GestureDetector(
                      child:
                          SearchPostFlowItemBuilder.buildWaterfallFlowPostItem(
                        context,
                        _postList[index],
                      ),
                    );
                  },
                  childCount: _postList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrainResultTab() {
    return EasyRefresh.builder(
      controller: _grainResultRefreshController,
      onRefresh: () async {
        return await _fetchGrainResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchGrainResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        controller: _grainResultScrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_grainList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无粮单",
                    ),
                  ),
              ],
            ),
          ),
          SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 0,
              crossAxisSpacing: 6,
              maxCrossAxisExtent: 600,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ItemBuilder.buildGrainRow(
                  context,
                  _grainList[index],
                  verticalPadding: 8,
                  onTap: () {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      GrainDetailScreen(
                          grainId: _grainList[index].id,
                          blogId: _grainList[index].userId),
                    );
                  },
                );
              },
              childCount: _grainList.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResultTab() {
    return EasyRefresh.builder(
      controller: _userResultRefreshController,
      onRefresh: () async {
        return await _fetchUserResult(refresh: true);
      },
      onLoad: () async {
        return await _fetchUserResult();
      },
      triggerAxis: Axis.vertical,
      childBuilder: (context, physics) => CustomScrollView(
        physics: physics,
        controller: _userResultScrollController,
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const SizedBox(height: 10),
                if (_userList.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    height: 160,
                    child: ItemBuilder.buildEmptyPlaceholder(
                      context: context,
                      text: "暂无用户",
                    ),
                  ),
              ],
            ),
          ),
          SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 0,
              crossAxisSpacing: 6,
              maxCrossAxisExtent: 400,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return ItemBuilder.buildUserRow(
                  context,
                  _userList[index],
                  onTap: () {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      UserDetailScreen(
                        blogId: _userList[index].blogInfo.blogId,
                        blogName: _userList[index].blogInfo.blogName,
                      ),
                    );
                  },
                );
              },
              childCount: _userList.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Hero(
      tag: "searchBar",
      child: Container(
        height: 35,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ItemBuilder.buildSearchBar(
                context: context,
                hintText: "搜标签、合集、粮单、文章、用户",
                onSubmitted: (value) {
                  Utils.addSearchHistory(value);
                  _performSearch(value);
                },
                controller: _searchController,
              ),
            ),
            if (!ResponsiveUtil.isLandscape()) const SizedBox(width: 16),
            if (!ResponsiveUtil.isLandscape())
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "取消",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
          ],
        ),
      ),
    );
  }
}
