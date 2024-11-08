import 'package:flutter/material.dart';
import 'package:loftify/Models/favorites_response.dart';
import 'package:loftify/Widgets/Item/item_builder.dart';

import '../../Api/user_api.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Utils/utils.dart';
import '../../generated/l10n.dart';
import '../General/EasyRefresh/easy_refresh.dart';
import 'bottom_sheet_builder.dart';
import 'input_bottom_sheet.dart';

class SubscribePostBottomSheet extends StatefulWidget {
  const SubscribePostBottomSheet({
    super.key,
    required this.postId,
    required this.blogId,
    this.onConfirm,
  });

  final int postId;
  final int blogId;
  final Function(List<String> folderIds)? onConfirm;

  @override
  SubscribePostBottomSheetState createState() =>
      SubscribePostBottomSheetState();
}

class SubscribePostBottomSheetState extends State<SubscribePostBottomSheet> {
  List<FavoriteFolder> _subscribeFolderList = [];
  List<FavoriteFolder> _favoriteFolderList = [];
  int _createCount = 0;
  bool _loading = false;

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
          _fetchSubscribeFolderList();
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

  _fetchSubscribeFolderList() async {
    return await UserApi.getSubscribeFolderList(
            postId: widget.postId, blogId: widget.blogId)
        .then((value) {
      try {
        if (value['code'] != 0) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          _subscribeFolderList.clear();
          for (var e in value['data']['subscribefolders']) {
            _subscribeFolderList.add(FavoriteFolder.fromJson(e));
          }
          for (var folder in _favoriteFolderList) {
            if (_subscribeFolderList.any((e) => e.id == folder.id)) {
              folder.postSubscribed = 1;
            }
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load folder list", e, t);
        if (mounted) IToast.showTop(S.current.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        color: Theme.of(context).canvasColor,
      ),
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          ItemBuilder.buildDivider(context, horizontal: 0, vertical: 0),
          Expanded(child: _buildButtons()),
          ItemBuilder.buildDivider(context, horizontal: 0, vertical: 0),
          _buildFooter(),
        ],
      ),
    );
  }

  _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(),
          Text(
            S.current.selectFolder,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ItemBuilder.buildClickItem(
            GestureDetector(
              onTap: () {
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
                          _fetchFavoriteFolderList();
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
              child: Text(
                S.current.newOp,
                style: Theme.of(context).textTheme.titleLarge?.apply(
                      fontSizeDelta: -2,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildButtons() {
    return EasyRefresh(
      refreshOnStart: true,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      triggerAxis: Axis.vertical,
      child: _favoriteFolderList.isNotEmpty
          ? ListView(
              cacheExtent: 9999,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: List.generate(
                _favoriteFolderList.length,
                (index) {
                  return _buildFolderItem(
                    context,
                    _favoriteFolderList[index],
                  );
                },
              ),
            )
          : ItemBuilder.buildEmptyPlaceholder(context: context, text: S.current.noFavoriteFolder),
    );
  }

  Widget _buildFolderItem(BuildContext context, FavoriteFolder item) {
    return Material(
      child: InkWell(
        onTap: () {
          item.postSubscribed = item.postSubscribed == 1 ? 0 : 1;
          setState(() {});
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      Text(
                        item.name ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "ID: ${item.id}",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
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
                icon: item.postSubscribed == 1
                    ? Icon(
                        Icons.check_circle_outline_rounded,
                        color: Theme.of(context).primaryColor,
                      )
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  item.postSubscribed = item.postSubscribed == 1 ? 0 : 1;
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildFooter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: S.current.cancel,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ItemBuilder.buildRoundButton(
              context,
              text: S.current.confirm,
              background: Theme.of(context).primaryColor,
              color: Colors.white,
              onTap: () {
                widget.onConfirm?.call(_favoriteFolderList
                    .where((e) => e.postSubscribed == 1)
                    .map((e) => e.id.toString())
                    .toList());
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
