import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Models/favorites_response.dart';

import '../../Api/user_api.dart';
import '../../Theme/loftify_design_theme.dart';
import '../../Utils/utils.dart';
import '../../l10n/l10n.dart';
import '../Design/loftify_controls.dart';
import '../Design/loftify_surfaces.dart';
import '../loftify_icons.dart';

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
  final List<FavoriteFolder> _subscribeFolderList = [];
  final List<FavoriteFolder> _favoriteFolderList = [];
  int _createCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<IndicatorResult> _fetchFavoriteFolderList({
    bool refresh = false,
  }) async {
    if (_loading) return IndicatorResult.none;
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
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  Future<IndicatorResult> _fetchSubscribeFolderList() async {
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
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
      }
    });
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchFavoriteFolderList(refresh: true);
  }

  Future<IndicatorResult> _onLoad() async {
    return await _fetchFavoriteFolderList();
  }

  @override
  Widget build(BuildContext context) {
    return LoftifySubscribePanelFrame(
      title: appLocalizations.selectFolder,
      createLabel: appLocalizations.newOp,
      onCreate: _showCreateFolder,
      body: _buildButtons(),
      footer: _buildFooter(),
    );
  }

  void _showCreateFolder() {
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
  }

  Widget _buildButtons() {
    return EasyRefresh(
      refreshOnStart: true,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      triggerAxis: Axis.vertical,
      child: _favoriteFolderList.isNotEmpty
          ? ListView.builder(
              cacheExtent: MediaQuery.sizeOf(context).height,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _favoriteFolderList.length,
              itemBuilder: (context, index) => KeyedSubtree(
                key: ValueKey(
                  'subscribe-folder-${_favoriteFolderList[index].id}',
                ),
                child: _buildFolderItem(
                  context,
                  _favoriteFolderList[index],
                ),
              ),
            )
          : EmptyPlaceholder(text: appLocalizations.noFavoriteFolder),
    );
  }

  Widget _buildFolderItem(BuildContext context, FavoriteFolder item) {
    final design = context.design;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () {
          item.postSubscribed = item.postSubscribed == 1 ? 0 : 1;
          setState(() {});
        },
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: design.spacing.xl,
            vertical: design.spacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: design.colors.outline,
                      width: design.borders.hairline),
                  borderRadius: BorderRadius.circular(design.radii.control),
                  color: Colors.transparent,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(design.radii.control),
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: ChewieItemBuilder.buildCachedImage(
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: design.typography.sectionTitle,
                      ),
                      SizedBox(height: design.spacing.md),
                      Text(
                        "ID: ${item.id}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: design.typography.metadata.copyWith(
                          color: design.colors.textMuted,
                        ),
                      ),
                      SizedBox(height: design.spacing.xs),
                      Text(
                        "${item.postCount}${appLocalizations.chapter}",
                        style: design.typography.metadata.copyWith(
                          color: design.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ChewieIconButton(
                icon: LoftifyIcons.select,
                selected: item.postSubscribed == 1,
                semanticLabel: item.name,
                onPressed: () {
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

  Widget _buildFooter() {
    return LoftifyResponsivePanelActions(
      secondary: LoftifyButton(
        label: appLocalizations.cancel,
        variant: LoftifyButtonVariant.secondary,
        expand: true,
        onPressed: () => Navigator.pop(context),
      ),
      primary: LoftifyButton(
        label: appLocalizations.confirm,
        expand: true,
        onPressed: () {
          widget.onConfirm?.call(_favoriteFolderList
              .where((e) => e.postSubscribed == 1)
              .map((e) => e.id.toString())
              .toList());
          Navigator.pop(context);
        },
      ),
    );
  }
}

class LoftifySubscribePanelFrame extends StatelessWidget {
  const LoftifySubscribePanelFrame({
    super.key,
    required this.title,
    required this.createLabel,
    required this.onCreate,
    required this.body,
    required this.footer,
  });

  final String title;
  final String createLabel;
  final VoidCallback onCreate;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final media = MediaQuery.of(context);
    final visibleHeight = (media.size.height - media.viewInsets.bottom)
        .clamp(0.0, double.infinity);
    final compactHeader = media.size.width < 380 ||
        media.textScaler.scale(1) > 1.35 ||
        visibleHeight * 0.8 < 420;
    final panelHeight =
        (visibleHeight * (compactHeader ? 0.92 : 0.8)).clamp(0.0, 720.0);
    final createAction = LoftifyButton(
      label: createLabel,
      variant: LoftifyButtonVariant.ghost,
      size: LoftifyButtonSize.compact,
      expand: compactHeader,
      onPressed: onCreate,
    );
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const ValueKey('loftify-subscribe-panel'),
        height: panelHeight,
        child: LoftifyPanel(
          title: title,
          trailing: compactHeader ? null : createAction,
          expandBody: true,
          body: compactHeader
              ? Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: design.spacing.xl,
                        vertical: design.spacing.md,
                      ),
                      child: createAction,
                    ),
                    Divider(
                      height: design.borders.hairline,
                      thickness: design.borders.hairline,
                      color: design.colors.outline,
                    ),
                    Expanded(child: body),
                  ],
                )
              : body,
          footer: footer,
          footerPadding: EdgeInsets.all(
            compactHeader ? design.spacing.md : design.spacing.xl,
          ),
        ),
      ),
    );
  }
}

class LoftifyResponsivePanelActions extends StatelessWidget {
  const LoftifyResponsivePanelActions({
    super.key,
    required this.secondary,
    required this.primary,
  });

  final Widget secondary;
  final Widget primary;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final stack = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.35;
    if (stack) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          primary,
          SizedBox(height: design.spacing.md),
          secondary,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: secondary),
        SizedBox(width: design.spacing.lg),
        Expanded(child: primary),
      ],
    );
  }
}
