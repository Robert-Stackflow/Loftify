import 'dart:io';

import 'package:context_menus/context_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/history_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Models/post_detail_response.dart';
import '../../Utils/constant.dart';
import '../../Utils/enums.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/PostItem/common_info_post_item_builder.dart';
import '../../generated/l10n.dart';
import 'nested_mixin.dart';

class LikeScreen extends StatefulWidgetForNested {
  LikeScreen({
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

  static const String routeName = "/info/like";

  @override
  State<LikeScreen> createState() => _LikeScreenState();
}

class _LikeScreenState extends State<LikeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<PostDetailData> _likeList = [];
  List<ArchiveData> _archiveDataList = [];
  int _total = 0;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  bool _noMore = false;
  InitPhase _initPhase = InitPhase.haveNotConnected;

  @override
  void initState() {
    if (Platform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark);
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
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

  _fetchLike({bool refresh = false}) async {
    if (_loading) return;
    if (refresh) _noMore = false;
    _loading = true;
    int offset = refresh ? 0 : _likeList.length;
    if (_initPhase != InitPhase.successful) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      String blogName = widget.infoMode == InfoMode.me
          ? blogInfo!.blogName
          : widget.blogName!;
      return await UserApi.getLikeList(blogName: blogName, offset: offset)
          .then((value) {
        try {
          if (value['meta']['status'] != 200) {
            if (Utils.isNotEmpty(
                value['meta']['desc'] ?? value['meta']['msg'])) {
              IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            }
            return IndicatorResult.fail;
          } else {
            _total = value['response']['count'];
            if (value['response']['archives'] != null) {
              _archiveDataList = [];
              List<ArchiveItem> archiveItems = [];
              List<dynamic> t = value['response']['archives'];
              for (var e in t) {
                archiveItems.add(ArchiveItem.fromJson(e));
              }
              for (var e in archiveItems) {
                for (var item in e.monthCount) {
                  if (item > 0) {
                    int month = e.monthCount.indexOf(item);
                    _archiveDataList.add(ArchiveData(
                      desc: S.current.yearAndMonth(e.year, month + 1),
                      count: item,
                      endTime: 0,
                      startTime: 0,
                    ));
                  }
                }
              }
              _archiveDataList.sort((a, b) => b.desc.compareTo(a.desc));
            }
            List<dynamic> t = value['response']['items'];
            if (refresh) _likeList.clear();
            for (var e in t) {
              if (e != null) {
                _likeList.add(PostDetailData.fromJson(e));
              }
            }
            if (mounted) setState(() {});
            _initPhase = InitPhase.successful;
            if (_likeList.length >= _total && !refresh) {
              _noMore = true;
              return IndicatorResult.noMore;
            } else {
              return IndicatorResult.success;
            }
          }
        } catch (e, t) {
          _initPhase = InitPhase.failed;
          ILogger.error("Failed to load like list", e, t);
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
    return await _fetchLike(refresh: true);
  }

  _onLoad() async {
    return await _fetchLike();
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
        return ItemBuilder.buildLoadingDialog(context,
            background: Colors.transparent);
      case InitPhase.failed:
        return ItemBuilder.buildError(
          context: context,
          onTap: _onRefresh,
        );
      case InitPhase.successful:
        return Stack(
          children: [
            EasyRefresh.builder(
              refreshOnStart: true,
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _onLoad,
              triggerAxis: Axis.vertical,
              childBuilder: (context, physics) {
                return _archiveDataList.isNotEmpty && _likeList.isNotEmpty
                    ? _buildNineGridGroup(physics)
                    : ItemBuilder.buildEmptyPlaceholder(
                        context: context,
                        text: S.current.noLike,
                        physics: physics,
                        shrinkWrap: false,
                      );
              },
            ),
            Positioned(
              right: ResponsiveUtil.isLandscape() ? 16 : 12,
              bottom: ResponsiveUtil.isLandscape() ? 16 : 76,
              child: _buildFloatingButtons(),
            ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildNineGridGroup(ScrollPhysics physics) {
    List<Widget> widgets = [];
    int startIndex = 0;
    for (var e in _archiveDataList) {
      if (_likeList.length < startIndex) {
        break;
      }
      if (e.count == 0) continue;
      int count = e.count;
      if (_likeList.length < startIndex + count) {
        count = _likeList.length - startIndex;
      }
      widgets.add(ItemBuilder.buildTitle(
        context,
        title: S.current.descriptionWithPostCount(e.desc, e.count.toString()),
        topMargin: 16,
        bottomMargin: 0,
      ));
      widgets.add(_buildNineGrid(startIndex, count));
      startIndex += e.count;
    }
    return ItemBuilder.buildLoadMoreNotification(
      noMore: _noMore,
      onLoad: _onLoad,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        physics: physics,
        children: widgets,
      ),
    );
  }

  Widget _buildNineGrid(int startIndex, int count) {
    return GridView.extent(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      shrinkWrap: true,
      maxCrossAxisExtent: 160,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (index) {
        int trueIndex = startIndex + index;
        return CommonInfoItemBuilder.buildNineGridPostItem(
            context, _likeList[trueIndex],
            wh: 160);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildDesktopAppBar(
      context: context,
      showBack: true,
      title: S.current.myLikes,
      actions: [
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showContextMenu(context, _buildMoreButtons());
            }),
        const SizedBox(width: 5),
      ],
    );
  }

  _buildMoreButtons() {
    return GenericContextMenu(
      buttonConfigs: [
        ContextMenuButtonConfig(
          S.current.clearInvalidContent,
          onPressed: () async {
            UserApi.deleteInvalidLike(blogId: await HiveUtil.getUserId())
                .then((value) {
              if (value['meta']['status'] != 200) {
                IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
              } else {
                _likeList
                    .removeWhere((e) => CommonInfoItemBuilder.isInvalid(e));
                setState(() {});
                IToast.showTop(S.current.clearSuccess);
              }
            });
          },
        ),
      ],
    );
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscape()
        ? Column(
            children: [
              ItemBuilder.buildShadowIconButton(
                context: context,
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
