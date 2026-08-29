import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';

import '../../Utils/utils.dart';
import '../../Widgets/Favorite/favorite_folder_card.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class FavoriteFolderListScreen extends StatefulWidget {
  const FavoriteFolderListScreen({super.key});

  static const String routeName = "/info/favoriteFolderList";

  @override
  State<FavoriteFolderListScreen> createState() =>
      _FavoriteFolderListScreenState();
}

class _FavoriteFolderListScreenState
    extends BaseDynamicState<FavoriteFolderListScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final List<FavoriteFolder> _favoriteFolderList = [];
  int _createCount = 0;
  bool _loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void initState() {
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
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
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
      backgroundColor: ChewieTheme.getBackground(context),
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
            right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
            bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
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
    return LoftifyFavoriteFolderCard(
      title: item.name ?? "",
      folderIdLabel: appLocalizations.folderId(item.id.toString()),
      postCountLabel: "${item.postCount}${appLocalizations.chapter}",
      editLabel: appLocalizations.edit,
      deleteLabel: appLocalizations.delete,
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          FavoriteFolderDetailScreen(favoriteFolderId: item.id ?? 0),
        );
      },
      onCopyTitle: () => ChewieUtils.copy(
        context,
        item.name ?? "",
        toastText: appLocalizations.haveCopiedFolderName,
      ),
      onCopyFolderId: () => ChewieUtils.copy(
        context,
        item.id.toString(),
        toastText: appLocalizations.haveCopiedFolderID,
      ),
      cover: ChewieItemBuilder.buildCachedImage(
        context: context,
        fit: BoxFit.cover,
        showLoading: false,
        imageUrl: Utils.removeWatermark(item.coverUrl ?? ""),
      ),
      onEdit: () {
        BottomSheetBuilder.showBottomSheet(
          context,
          (sheetContext) => InputBottomSheet(
            title: appLocalizations.editFolderTitle,
            hint: appLocalizations.inputFolderTitle,
            text: item.name ?? "",
            onConfirm: (text) {
              var tmp = item;
              tmp.name = text;
              UserApi.editFolder(folder: tmp).then((value) {
                if (value['code'] == 0) {
                  IToast.showTop(appLocalizations.editSuccess);
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
      onDelete: item.isDefault == 1
          ? null
          : () {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.deleteFolder,
                message:
                    appLocalizations.deleteFolderMessage(item.name.toString()),
                messageTextAlign: TextAlign.center,
                onTapConfirm: () async {
                  UserApi.deleteFolder(folderId: item.id ?? 0).then((value) {
                    if (value['code'] == 0) {
                      IToast.showTop(appLocalizations.deleteSuccess);
                      _refreshController.callRefresh();
                    } else {
                      IToast.showTop(value['msg']);
                    }
                  });
                },
              );
            },
    );
  }

  handleAdd() {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => InputBottomSheet(
        title: appLocalizations.newFolder,
        hint: appLocalizations.inputFolderTitle,
        text: "",
        onConfirm: (text) {
          UserApi.createFolder(name: text).then((value) {
            if (value['code'] == 0) {
              IToast.showTop(appLocalizations.createSuccess);
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
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.myFavorites,
      actions: [
        ChewieIconButton(
          icon: LoftifyIcons.add,
          tooltip: appLocalizations.newFolder,
          onPressed: handleAdd,
        ),
      ],
    );
  }

  _buildFloatingButtons() {
    return ResponsiveUtil.isLandscapeLayout()
        ? Column(
            children: [
              ShadowIconButton(
                icon: const ChewieIcon(LoftifyIcons.add),
                onTap: handleAdd,
              ),
            ],
          )
        : emptyWidget;
  }
}
