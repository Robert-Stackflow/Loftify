import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';

import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';

class FavoriteFolderListScreen extends StatefulWidget {
  const FavoriteFolderListScreen({super.key});

  static const String routeName = "/info/favoriteFolderList";

  @override
  State<FavoriteFolderListScreen> createState() =>
      _FavoriteFolderListScreenState();
}

class _FavoriteFolderListScreenState extends State<FavoriteFolderListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<FavoriteFolder> _favoriteFolderList = [];
  int _createCount = 0;
  int _subscribeCount = 0;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();

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

  _fetchFavoriteFolderList({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    int offset = refresh ? 0 : _favoriteFolderList.length;
    return await UserApi.getFavoriteFolderList(offset: offset).then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop( value['msg']);
          return IndicatorResult.fail;
        } else {
          _createCount = value['data']['createCount'];
          _subscribeCount = value['data']['subscribeCount'];
          _favoriteFolderList.clear();
          for (var e in value['data']['folders']) {
            _favoriteFolderList.add(FavoriteFolder.fromJson(e));
          }
          if (_favoriteFolderList.length == _createCount && !refresh) {
            return IndicatorResult.noMore;
          } else {
            return IndicatorResult.success;
          }
        }
      } catch (e) {
        if (mounted) IToast.showTop( "加载失败");
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  _onRefresh() async {
    return await _fetchFavoriteFolderList(refresh: true);
  }

  _onLoad() async {
    return await _fetchFavoriteFolderList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh(
        refreshOnStart: true,
        controller: _refreshController,
        onRefresh: _onRefresh,
        onLoad: _onLoad,
        triggerAxis: Axis.vertical,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      cacheExtent: 9999,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      children: List.generate(_favoriteFolderList.length, (index) {
        return GestureDetector(
          onTap: () {
            RouteUtil.pushCupertinoRoute(
              context,
              FavoriteFolderDetailScreen(
                  favoriteFolderId: _favoriteFolderList[index].id ?? 0),
            );
          },
          child: _buildFolderItem(
            context,
            _favoriteFolderList[index],
          ),
        );
      }),
    );
  }

  static Widget _buildFolderItem(BuildContext context, FavoriteFolder item) {
    return Container(
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: Theme.of(context).dividerColor, width: 0.5),
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 80,
                width: 80,
                child: ItemBuilder.buildCachedImage(
                  context: context,
                  fit: BoxFit.cover,
                  showLoading: false,
                  imageUrl: Utils.removeWatermark(item.coverUrl ?? ""),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  ItemBuilder.buildCopyItem(
                    context,
                    child: Text(
                      item.name ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    copyText: item.name ?? "",
                    toastText: "已复制收藏夹名称",
                  ),
                  const SizedBox(height: 10),
                  ItemBuilder.buildCopyItem(context,
                      child: Text(
                        "ID: ${item.id}",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      copyText: item.id.toString(),
                      toastText: "已复制收藏夹ID"),
                  const SizedBox(height: 10),
                  Text(
                    "${item.postCount}篇",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildAppBar(
      context: context,
      leading: Icons.arrow_back_rounded,
      backgroundColor: AppTheme.getBackground(context),
      onLeadingTap: () {
        Navigator.pop(context);
      },
      title: Text("我的收藏", style: Theme.of(context).textTheme.titleLarge),
      actions: [
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.search_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {}),
        const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {}),
        const SizedBox(width: 5),
      ],
    );
  }
}
