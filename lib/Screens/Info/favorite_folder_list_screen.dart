import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';
import 'package:loftify/Widgets/Dialog/dialog_builder.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import '../../Utils/constant.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/responsive_util.dart';
import '../../Utils/route_util.dart';
import '../../Utils/utils.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/input_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

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
          IToast.showTop(value['msg']);
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
      } catch (e, t) {
        ILogger.error("Failed to load folder list", e, t);
        if (mounted) IToast.showTop(S.current.loadFailed);
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
      backgroundColor: MyTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          EasyRefresh(
            refreshOnStart: true,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoad: _onLoad,
            triggerAxis: Axis.vertical,
            child: _buildBody(),
          ),
          Positioned(
            right: ResponsiveUtil.isLandscape() ? 16 : 12,
            bottom: ResponsiveUtil.isLandscape() ? 16 : 76,
            child: _buildFloatingButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return WaterfallFlow.extent(
      maxCrossAxisExtent: 600,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      children: List.generate(_favoriteFolderList.length, (index) {
        return _buildFolderItem(
          context,
          _favoriteFolderList[index],
        );
      }),
    );
  }

  Widget _buildFolderItem(BuildContext context, FavoriteFolder item) {
    return ItemBuilder.buildClickable(
      GestureDetector(
        onTap: () {
          RouteUtil.pushPanelCupertinoRoute(
            context,
            FavoriteFolderDetailScreen(favoriteFolderId: item.id ?? 0),
          );
        },
        child: Container(
          color: Colors.transparent,
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).dividerColor, width: 0.5),
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
                      ItemBuilder.buildCopyable(
                        context,
                        child: Text(
                          item.name ?? "",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        text: item.name ?? "",
                        toastText: S.current.haveCopiedFolderName,
                      ),
                      const SizedBox(height: 10),
                      ItemBuilder.buildCopyable(context,
                          child: Text(
                            S.current.folderId(item.id.toString()),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          text: item.id.toString(),
                          toastText: S.current.haveCopiedFolderID),
                      const SizedBox(height: 10),
                      Text(
                        "${item.postCount}${S.current.chapter}",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              ItemBuilder.buildIconButton(
                context: context,
                icon: const Icon(Icons.edit_note_rounded),
                onTap: () {
                  BottomSheetBuilder.showBottomSheet(
                    context,
                    (sheetContext) => InputBottomSheet(
                      buttonText: S.current.confirm,
                      title: S.current.editFolderTitle,
                      hint: S.current.inputFolderTitle,
                      text: item.name ?? "",
                      onConfirm: (text) {
                        var tmp = item;
                        tmp.name = text;
                        UserApi.editFolder(folder: tmp).then((value) {
                          if (value['code'] == 0) {
                            IToast.showTop(S.current.editSuccess);
                            item.name = text;
                            setState(() {});
                          } else {
                            IToast.showTop(value['msg']);
                          }
                        });
                      },
                    ),
                    preferMinWidth: 400,
                    responsive: true,
                  );
                },
              ),
              if (item.isDefault != 1)
                ItemBuilder.buildIconButton(
                  context: context,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  onTap: () {
                    DialogBuilder.showConfirmDialog(
                      context,
                      title: S.current.deleteFolder,
                      message:
                          S.current.deleteFolderMessage(item.name.toString()),
                      messageTextAlign: TextAlign.center,
                      onTapConfirm: () async {
                        UserApi.deleteFolder(folderId: item.id ?? 0)
                            .then((value) {
                          if (value['code'] == 0) {
                            IToast.showTop(S.current.deleteSuccess);
                            _refreshController.callRefresh();
                          } else {
                            IToast.showTop(value['msg']);
                          }
                        });
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  handleAdd() {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => InputBottomSheet(
        buttonText: S.current.confirm,
        title: S.current.newFolder,
        hint: S.current.inputFolderTitle,
        text: "",
        onConfirm: (text) {
          UserApi.createFolder(name: text).then((value) {
            if (value['code'] == 0) {
              IToast.showTop(S.current.createSuccess);
              _refreshController.callRefresh();
            } else {
              IToast.showTop(value['msg']);
            }
          });
        },
      ),
      preferMinWidth: 400,
      responsive: true,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ItemBuilder.buildResponsiveAppBar(
      context: context,
      showBack: true,
      title: S.current.myFavorites,
      actions: [
        // ItemBuilder.buildIconButton(
        //     context: context,
        //     icon: Icon(Icons.search_rounded,
        //         color: Theme.of(context).iconTheme.color),
        //     onTap: () {}),
        // const SizedBox(width: 5),
        ItemBuilder.buildIconButton(
          context: context,
          icon:
              Icon(Icons.add_rounded, color: Theme.of(context).iconTheme.color),
          onTap: handleAdd,
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscape()
        ? Column(
            children: [
              ItemBuilder.buildShadowIconButton(
                context: context,
                icon: const Icon(Icons.add_rounded),
                onTap: handleAdd,
              ),
            ],
          )
        : emptyWidget;
  }
}
