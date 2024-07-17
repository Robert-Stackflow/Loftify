import 'package:blur/blur.dart';
import 'package:flutter/material.dart' hide AnimatedSlide;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/grain_api.dart';
import 'package:loftify/Models/grain_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Screens/Post/post_detail_screen.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';
import 'package:loftify/Widgets/PostItem/grain_post_item_builder.dart';
import 'package:tuple/tuple.dart';

import '../../Models/enums.dart';
import '../../Models/history_response.dart';
import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/uri_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/Custom/auto_slideup_panel.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/General/Animation/animated_fade.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';

const double minCardHeightFraction = 0.63;

class GrainDetailScreen extends StatefulWidget {
  const GrainDetailScreen({
    super.key,
    required this.grainId,
    required this.blogId,
  });

  final int grainId;
  final int blogId;

  static const String routeName = "/grain/detail";

  @override
  GrainDetailScreenState createState() => GrainDetailScreenState();
}

class GrainDetailScreenState extends State<GrainDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _rotateController;
  final EasyRefreshController _refreshController = EasyRefreshController();
  String grainUrl = "";

  Animation<double> get textFadeAnimation =>
      Tween(begin: 1.0, end: 0.0).animate(_slideController);
  bool subscribed = false;
  GrainDetailData? grainDetailData;
  bool loading = false;
  List<GrainPostItem> posts = [];
  final List<ArchiveData> _archiveDataList = [];
  bool isOldest = false;

  _fetchIncantation() {
    GrainApi.getIncantation(
      grainId: widget.grainId,
      blogId: widget.blogId,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          if (value['data']['grainLink'] != null) {
            grainUrl = value['data']['grainLink'];
          }
        }
      } catch (e) {
        if (mounted) IToast.showTop(context, text: "获取链接失败");
        return IndicatorResult.fail;
      }
    });
  }

  _fetchData({bool refresh = false, bool showLoading = false}) async {
    if (loading) return;
    if (showLoading) CustomLoadingDialog.showLoading(context, title: "加载中...");
    loading = true;
    int offset = refresh ? 0 : grainDetailData?.offset ?? 0;
    return await GrainApi.getGrainDetail(
      grainId: widget.grainId,
      blogId: widget.blogId,
      offset: offset,
      sortType: isOldest ? 0 : 1,
    ).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(context, text: value['msg']);
          return IndicatorResult.fail;
        } else {
          GrainDetailData t = GrainDetailData.fromJson(value['data']);
          if (grainDetailData == null || refresh) {
            grainDetailData = t;
            subscribed = grainDetailData!.followStatus;
          } else if (grainDetailData != null) {
            grainDetailData!.offset = t.offset;
          }
          List<GrainPostItem> newPosts = [];
          if (refresh) posts.clear();
          for (var e in t.posts) {
            if (posts.indexWhere((element) =>
                    element.postData.postView.id == e.postData.postView.id) ==
                -1) {
              newPosts.add(e);
            }
          }
          posts.addAll(newPosts);
          Map<String, int> monthCount = {};
          for (var e in posts) {
            String yearMonth = Utils.formatYearMonth(e.opTime);
            monthCount.putIfAbsent(yearMonth, () => 0);
            monthCount[yearMonth] = monthCount[yearMonth]! + 1;
          }
          _archiveDataList.clear();
          for (var e in monthCount.keys) {
            _archiveDataList.add(ArchiveData(
              desc: e,
              count: monthCount[e] ?? 0,
              endTime: 0,
              startTime: 0,
            ));
          }
          if (mounted) setState(() {});
          if (posts.length >= grainDetailData!.grainInfo.postCount ||
              newPosts.isEmpty) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e) {
        if (mounted) IToast.showTop(context, text: "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (showLoading) CustomLoadingDialog.dismissLoading(context);
        if (mounted) setState(() {});
        loading = false;
      }
    });
  }

  _onRefresh() async {
    await _fetchData(refresh: true);
  }

  _onLoad() async {
    return await _fetchData();
  }

  @override
  void initState() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    super.initState();
    _fetchData(refresh: true);
    _fetchIncantation();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: grainDetailData != null ? _buildFooter() : null,
      body: grainDetailData != null
          ? Stack(
              children: [
                _buildBackground(),
                _buildInfoCard(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAppBar(),
                    AnimatedFade(
                      animation: textFadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(),
                          const SizedBox(height: 10),
                          _buildStatisticRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : ItemBuilder.buildLoadingDialog(
              context,
              background: Colors.transparent,
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 65,
      width: MediaQuery.sizeOf(context).width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: subscribed ? "取消订阅" : "订阅粮单",
              background: Theme.of(context).primaryColor.withAlpha(40),
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: Theme.of(context).primaryColor,
              onTap: () {
                HapticFeedback.mediumImpact();
                GrainApi.subscribeOrUnSubscribe(
                  grainId: widget.grainId,
                  blogId: widget.blogId,
                  isSubscribe: !subscribed,
                ).then((value) {
                  if (value['code'] != 0) {
                    IToast.showTop(context, text: value['msg']);
                  } else {
                    subscribed = !subscribed;
                    setState(() {});
                  }
                });
              },
              fontSizeDelta: 2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: "开始阅读",
              background: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              onTap: () {
                if (posts.isNotEmpty) {
                  RouteUtil.pushCupertinoRoute(
                    context,
                    PostDetailScreen(
                      grainPostItem: posts[0],
                      isArticle: GrainPostItemBuilder.getPostType(posts[0]) ==
                          PostType.article,
                    ),
                  );
                } else {
                  IToast.showTop(context, text: "粮单中暂无文章");
                }
              },
              fontSizeDelta: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    bool hasDesc = Utils.isNotEmpty(
      grainDetailData!.grainInfo.description,
    );
    return AutoSlideUpPanel(
      minHeight: MediaQuery.sizeOf(context).height - 335,
      maxHeight: Utils.getMaxHeight(context) - 65,
      onPanelSlide: (position) => _slideController.value = position,
      panelBuilder: (ScrollController controller) {
        return Container(
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.getBackground(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: NestedScrollView(
            controller: controller,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              hasDesc
                                  ? grainDetailData!.grainInfo.description
                                  : "暂无简介",
                              style:
                                  Theme.of(context).textTheme.labelLarge?.apply(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                            ),
                          ),
                          ItemBuilder.buildIconTextButton(
                            context,
                            text: isOldest ? "最旧" : "最新",
                            quarterTurns: 3,
                            icon: Icon(
                              isOldest
                                  ? Icons.switch_right_rounded
                                  : Icons.switch_left_rounded,
                              color: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.color,
                              size: 18,
                            ),
                            fontSizeDelta: 1,
                            color:
                                Theme.of(context).textTheme.labelMedium?.color,
                            onTap: () {
                              setState(() {
                                isOldest = !isOldest;
                              });
                              _fetchData(refresh: true, showLoading: true);
                            },
                          ),
                        ],
                      ),
                      if (grainDetailData!.grainInfo.tags.isNotEmpty)
                        _buildTagList(),
                      ItemBuilder.buildDivider(
                        context,
                        horizontal: 0,
                        vertical:
                            grainDetailData!.grainInfo.tags.isEmpty ? 10 : 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: _buildNineGridGroup(controller),
          ),
        );
      },
    );
  }

  _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ItemBuilder.buildHeroCachedImage(
              imageUrl: grainDetailData!.grainInfo.coverUrl,
              context: context,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              tagPrefix: Utils.getRandomString(),
              title: "粮单封面",
              showLoading: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  grainDetailData!.grainInfo.name,
                  style: Theme.of(context).textTheme.titleMedium?.apply(
                        fontSizeDelta: 2,
                        color: Colors.white,
                        fontWeightDelta: 2,
                      ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    RouteUtil.pushCupertinoRoute(
                      context,
                      UserDetailScreen(
                        blogId: widget.blogId,
                        blogName: grainDetailData!.blogInfo.blogName,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: ItemBuilder.buildAvatar(
                          context: context,
                          imageUrl: grainDetailData!.blogInfo.bigAvaImg,
                          size: 20,
                          showBorder: false,
                          showLoading: false,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${grainDetailData!.blogInfo.blogNickName} · 更新于${Utils.formatTimestamp(grainDetailData!.grainInfo.updateTime)}",
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.apply(color: Colors.white, fontSizeDelta: -1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildStatisticRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ItemBuilder.buildStatisticItem(
          context,
          title: '文章数',
          count: grainDetailData!.grainInfo.postCount,
          onTap: () {},
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: '订阅数',
          count: grainDetailData!.grainInfo.subscribedCount,
          onTap: () {},
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: '共创数',
          count: grainDetailData!.grainInfo.joinCount,
          onTap: () {},
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
        ItemBuilder.buildStatisticItem(
          context,
          title: '浏览量',
          count: grainDetailData!.grainInfo.viewCount,
          onTap: () {},
          countColor: Colors.white,
          labelColor: Colors.white.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildTagList() {
    Map<String, TagType> tags = {};
    for (var e in grainDetailData!.grainInfo.tags) {
      tags[e] = TagType.normal;
    }
    List<MapEntry<String, TagType>> sortedTags = tags.entries.toList();
    sortedTags.sort((a, b) => b.value.index.compareTo(a.value.index));
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(sortedTags.length, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ItemBuilder.buildTagItem(
              context,
              sortedTags[index].key,
              sortedTags[index].value,
              showIcon: false,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNineGridGroup(ScrollController controller) {
    List<Widget> widgets = [];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (posts.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (posts.length < startIndex + count) {
        count = posts.length - startIndex;
      }
      widgets.add(ItemBuilder.buildTitle(
        context,
        title: "${e.desc}（${e.count}篇）",
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return EasyRefresh(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: widgets,
      ),
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.extent(
      padding: const EdgeInsets.only(top: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return GrainPostItemBuilder.buildNineGridPostItem(
          context,
          posts[trueIndex],
          wh: 160,
        );
      }),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0),
            Colors.black.withOpacity(0.4),
          ],
        ),
      ),
      child: ItemBuilder.buildAppBar(
        transparent: true,
        leading: Icons.arrow_back_rounded,
        leadingColor: Colors.white,
        center: true,
        title: Text(
          "粮单",
          style: Theme.of(context).textTheme.titleMedium?.apply(
                color: Colors.white,
                fontWeightDelta: 2,
              ),
        ),
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
            onTap: () {
              List<Tuple2<String, dynamic>> options = [
                const Tuple2("复制链接", 0),
                const Tuple2("在浏览器打开", 1),
                const Tuple2("分享到其他应用", 2),
              ];
              BottomSheetBuilder.showListBottomSheet(
                context,
                (sheetContext) => TileList.fromOptions(
                  options,
                  (idx) {
                    if (idx == 0) {
                      Utils.copy(context, grainUrl);
                    } else if (idx == 1) {
                      UriUtil.openExternal(grainUrl);
                    } else if (idx == 2) {
                      UriUtil.share(context, grainUrl);
                    }
                    Navigator.pop(sheetContext);
                  },
                  showCancel: true,
                  context: context,
                  showTitle: false,
                  onCloseTap: () => Navigator.pop(sheetContext),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              );
            },
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
        ],
        onLeadingTap: () {
          Navigator.pop(context);
        },
        context: context,
      ),
    );
  }

  Widget _buildBackground() {
    String backgroudUrl = grainDetailData!.grainInfo.coverUrl;
    return Blur(
      blur: 20,
      blurColor: Colors.black12,
      child: ItemBuilder.buildCachedImage(
        context: context,
        imageUrl: backgroudUrl,
        fit: BoxFit.cover,
        showLoading: false,
        width: MediaQuery.sizeOf(context).width * 2,
        height:
            MediaQuery.sizeOf(context).height * (1.1 - minCardHeightFraction),
        placeholderBackground: Theme.of(context).textTheme.labelSmall?.color,
        bottomPadding: 50,
      ),
    );
  }
}
