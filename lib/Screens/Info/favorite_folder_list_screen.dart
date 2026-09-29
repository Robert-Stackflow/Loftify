import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Screens/Info/favorite_folder_detail_screen.dart';

import '../../Utils/app_provider.dart';
import '../../Utils/enums.dart';
import '../../Utils/utils.dart';
import '../../Widgets/Design/loftify_state_view.dart';
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
  final Set<int> _pendingEditIds = {};
  final Set<int> _pendingDeleteIds = {};
  bool _creatingFolder = false;
  InitPhase _initPhase = InitPhase.connecting;
  final EasyRefreshController _refreshController = EasyRefreshController();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<IndicatorResult> _fetchFavoriteFolderList(
      {bool refresh = false}) async {
    if (_loading || !mounted) return IndicatorResult.none;
    final token = appProvider.token;
    bool isCurrentAccount() => mounted && appProvider.token == token;
    if (token.isEmpty) {
      setState(() {
        _favoriteFolderList.clear();
        _createCount = 0;
        _initPhase = InitPhase.failed;
      });
      return IndicatorResult.fail;
    }
    _loading = true;
    final offset = refresh ? 0 : _favoriteFolderList.length;
    if (_favoriteFolderList.isEmpty) {
      _initPhase = InitPhase.connecting;
      setState(() {});
    }
    try {
      final value = await UserApi.getFavoriteFolderList(offset: offset);
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (value['code'] != 0) {
        if (_favoriteFolderList.isEmpty) _initPhase = InitPhase.failed;
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      }
      final count = value['data']['createCount'] as int;
      final folders = (value['data']['folders'] as List)
          .map((item) => FavoriteFolder.fromJson(item))
          .toList();
      _createCount = count;
      if (refresh) _favoriteFolderList.clear();
      final existingIds =
          _favoriteFolderList.map((folder) => folder.id).toSet();
      for (final folder in folders) {
        if (existingIds.add(folder.id)) _favoriteFolderList.add(folder);
      }
      _initPhase = InitPhase.successful;
      if (!refresh &&
          (folders.isEmpty || _favoriteFolderList.length >= _createCount)) {
        return IndicatorResult.noMore;
      }
      return IndicatorResult.success;
    } catch (error, stackTrace) {
      if (!isCurrentAccount()) return IndicatorResult.none;
      if (_favoriteFolderList.isEmpty) _initPhase = InitPhase.failed;
      ILogger.error('Failed to load folder list', error, stackTrace);
      IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      if (mounted) {
        setState(() {
          if (!isCurrentAccount()) {
            _favoriteFolderList.clear();
            _createCount = 0;
            _initPhase = InitPhase.failed;
          }
        });
      }
      _loading = false;
    }
  }

  Future<IndicatorResult> _onRefresh() =>
      _fetchFavoriteFolderList(refresh: true);

  Future<IndicatorResult> _onLoad() => _fetchFavoriteFolderList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          EasyRefresh.builder(
            refreshOnStart: true,
            controller: _refreshController,
            onRefresh: _onRefresh,
            onLoad: _onLoad,
            triggerAxis: Axis.vertical,
            childBuilder: (context, physics) {
              if (_initPhase != InitPhase.successful) {
                final loading = _initPhase == InitPhase.connecting;
                return CustomScrollView(
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
                        onAction: loading
                            ? null
                            : () => _refreshController.callRefresh(),
                      ),
                    ),
                  ],
                );
              }
              if (_favoriteFolderList.isEmpty) {
                return EmptyPlaceholder(
                  text: appLocalizations.noFavoriteFolder,
                  physics: physics,
                  shrinkWrap: false,
                );
              }
              return _buildBody(physics);
            },
          ),
          if (_initPhase == InitPhase.successful)
            Positioned(
              right: ResponsiveUtil.isLandscapeLayout() ? 16 : 12,
              bottom: ResponsiveUtil.isLandscapeLayout() ? 16 : 76,
              child: _buildFloatingButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return WaterfallFlow.extent(
      physics: physics,
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
            onConfirm: (text) => _editFolder(item, text),
          ),
          preferMinWidth: 400,
          responsive: true,
        );
      },
      onDelete: item.isDefault == 1 || item.id == null
          ? null
          : () {
              DialogBuilder.showConfirmDialog(
                context,
                title: appLocalizations.deleteFolder,
                message:
                    appLocalizations.deleteFolderMessage(item.name.toString()),
                messageTextAlign: TextAlign.center,
                onTapConfirm: () => _deleteFolder(item.id!),
              );
            },
    );
  }

  Future<void> _editFolder(FavoriteFolder item, String name) async {
    final id = item.id;
    if (id == null || !_pendingEditIds.add(id)) return;
    final token = appProvider.token;
    final edited = FavoriteFolder.fromJson({
      ...item.toJson(),
      'name': name,
      'tags': item.tags ?? <String>[],
      'themes': item.themes ?? <String>[],
    });
    try {
      final value = await UserApi.editFolder(folder: edited);
      if (!mounted || appProvider.token != token) return;
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
        return;
      }
      setState(() {
        for (final folder in _favoriteFolderList) {
          if (folder.id == id) folder.name = name;
        }
      });
      IToast.showTop(appLocalizations.editSuccess);
    } catch (error, stackTrace) {
      ILogger.error('Failed to edit favorite folder', error, stackTrace);
      if (mounted && appProvider.token == token) {
        IToast.showTop(appLocalizations.loadFailed);
      }
    } finally {
      _pendingEditIds.remove(id);
    }
  }

  Future<void> _deleteFolder(int id) async {
    if (!_pendingDeleteIds.add(id)) return;
    final token = appProvider.token;
    try {
      final value = await UserApi.deleteFolder(folderId: id);
      if (!mounted || appProvider.token != token) return;
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
        return;
      }
      setState(() {
        _favoriteFolderList.removeWhere((folder) => folder.id == id);
        _createCount = (_createCount - 1).clamp(0, _createCount);
      });
      IToast.showTop(appLocalizations.deleteSuccess);
      _refreshController.callRefresh();
    } catch (error, stackTrace) {
      ILogger.error('Failed to delete favorite folder', error, stackTrace);
      if (mounted && appProvider.token == token) {
        IToast.showTop(appLocalizations.loadFailed);
      }
    } finally {
      _pendingDeleteIds.remove(id);
    }
  }

  Future<void> _createFolder(String name) async {
    if (_creatingFolder) return;
    _creatingFolder = true;
    final token = appProvider.token;
    try {
      final value = await UserApi.createFolder(name: name);
      if (!mounted || appProvider.token != token) return;
      if (value['code'] != 0) {
        IToast.showTop(value['msg']);
        return;
      }
      IToast.showTop(appLocalizations.createSuccess);
      _refreshController.callRefresh();
    } catch (error, stackTrace) {
      ILogger.error('Failed to create favorite folder', error, stackTrace);
      if (mounted && appProvider.token == token) {
        IToast.showTop(appLocalizations.loadFailed);
      }
    } finally {
      _creatingFolder = false;
    }
  }

  void handleAdd() {
    BottomSheetBuilder.showBottomSheet(
      context,
      (sheetContext) => InputBottomSheet(
        title: appLocalizations.newFolder,
        hint: appLocalizations.inputFolderTitle,
        text: "",
        onConfirm: _createFolder,
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

  Widget _buildFloatingButtons() {
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
