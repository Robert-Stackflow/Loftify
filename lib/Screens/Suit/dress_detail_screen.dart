import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loftify/Api/dress_api.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/enums.dart';
import '../../Utils/loftify_file_util.dart';
import '../../Widgets/Design/loftify_download_progress_button.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class DressDetailScreen extends StatefulWidgetForNested {
  const DressDetailScreen({
    super.key,
    required this.returnGiftDressId,
    super.nested = false,
  });

  final int returnGiftDressId;

  static const String routeName = "/info/dressDetail";

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends BaseDynamicState<DressDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GiftDress? _giftDress;
  bool _loading = false;
  String? userAvatarImg;
  String? currentAvatarImg;
  final EasyRefreshController _refreshController = EasyRefreshController();
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    currentAvatarImg = ChewieHiveUtil.getString(HiveUtil.customAvatarBoxKey,
        defaultValue: null);
    setState(() {});
  }

  Future<IndicatorResult> _fetchDetail({bool refresh = false}) async {
    if (_loading) return IndicatorResult.none;
    _loading = true;
    try {
      userAvatarImg = (await HiveUtil.getUserInfo())?.bigAvaImg;
      final value = await DressApi.getDressDetail(
        returnGiftDressId: widget.returnGiftDressId,
      );
      if (value['code'] != 200) {
        IToast.showTop(value['msg']);
        return IndicatorResult.fail;
      }
      _giftDress = GiftDress.fromJson(value['data']['returnGiftDress']);
      _giftDress!.partList.sort((a, b) => a.partType.compareTo(b.partType));
      return IndicatorResult.success;
    } catch (e, t) {
      ILogger.error("Failed to load dress detail", e, t);
      if (mounted) IToast.showTop(appLocalizations.loadFailed);
      return IndicatorResult.fail;
    } finally {
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<IndicatorResult> _onRefresh() => _fetchDetail(refresh: true);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: _buildAppBar(),
      body: EasyRefresh.builder(
          refreshOnStart: true,
          controller: _refreshController,
          onRefresh: _onRefresh,
          triggerAxis: Axis.vertical,
          childBuilder: (context, physics) {
            return _buildBody(physics);
          }),
    );
  }

  Widget _buildBody(ScrollPhysics physics) {
    return CustomScrollView(
      physics: physics,
      cacheExtent: MediaQuery.sizeOf(context).height,
      slivers: [
        if (_giftDress != null)
          SliverToBoxAdapter(child: _buildDressHeader(_giftDress!)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          sliver: SliverWaterfallFlow(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              maxCrossAxisExtent: 300,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItem(_giftDress!.partList[index]),
              childCount: _giftDress?.partList.length ?? 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDressHeader(GiftDress dress) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ChewieItemBuilder.buildCachedImage(
              imageUrl: dress.coverImg,
              context: context,
              showLoading: false,
              placeholderBackground: Colors.transparent,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dress.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  StringUtil.isNotEmpty(dress.creatorNickName)
                      ? dress.creatorNickName
                      : appLocalizations.dressDetail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appLocalizations.pendantCount(dress.partCount),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _dressOrUnDress(GiftPartItem item) async {
    HapticFeedback.mediumImpact();
    if (currentAvatarImg == item.partUrl) {
      await ChewieHiveUtil.put(HiveUtil.customAvatarBoxKey, "");
      currentAvatarImg = "";
      setState(() {});
      IToast.showTop(appLocalizations.unDressSuccess);
    } else {
      await ChewieHiveUtil.put(HiveUtil.customAvatarBoxKey, item.partUrl);
      currentAvatarImg = item.partUrl;
      setState(() {});
      IToast.showTop(appLocalizations.dressSuccess);
    }
  }

  Widget _buildItem(GiftPartItem item) {
    final isAvatarBox = item.partType == 1;
    final isDressing = currentAvatarImg == item.partUrl;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 176,
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(18),
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
            child: isAvatarBox
                ? ItemBuilder.buildAvatar(
                    context: context,
                    size: 92,
                    showLoading: false,
                    imageUrl: userAvatarImg ?? "",
                    avatarBoxImageUrl: item.partUrl,
                    tagPrefix: "dressAvatarBox${item.partName}",
                    showDetailMode: ShowDetailMode.avatarBox,
                  )
                : GestureDetector(
                    onTap: () {
                      RouteUtil.pushDialogRoute(
                        context,
                        showClose: false,
                        fullScreen: true,
                        useFade: true,
                        opaque: false,
                        HeroPhotoViewScreen(
                          imageUrls: [item.partUrl],
                          useMainColor: false,
                          title: item.partName,
                        ),
                      );
                    },
                    child: Hero(
                      tag: item.partUrl,
                      child: ChewieItemBuilder.buildCachedImage(
                        context: context,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        showLoading: false,
                        placeholderBackground: Colors.transparent,
                        imageUrl: item.img,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.partName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvatarBox
                      ? appLocalizations.avatarBox
                      : appLocalizations.commentBubble,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                LoftifyDownloadProgressIconButton(
                  semanticLabel: appLocalizations.download,
                  icon: LoftifyIcons.download,
                  progress: _downloadProgress[item.partUrl],
                  onPressed: _downloadProgress.containsKey(item.partUrl)
                      ? null
                      : () => _downloadPart(item),
                ),
                if (isAvatarBox) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _dressOrUnDress(item),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                      child: Text(
                        isDressing
                            ? appLocalizations.dressingCurrently
                            : appLocalizations.dressImmediately,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPart(GiftPartItem item) async {
    final key = item.partUrl;
    if (_downloadProgress.containsKey(key)) return;
    setState(() => _downloadProgress[key] = 0);
    try {
      final success = await LoftifyFileUtil.saveImage(
        context,
        key,
        onReceiveProgress: (received, total) {
          _updateDownloadProgress(key, received, total);
        },
      );
      await _showDownloadCompletion(key, success);
    } finally {
      if (mounted) setState(() => _downloadProgress.remove(key));
    }
  }

  void _updateDownloadProgress(String key, int received, int total) {
    if (!mounted || !_downloadProgress.containsKey(key) || total <= 0) return;
    final next = (received / total).clamp(0.0, 1.0).toDouble();
    final current = _downloadProgress[key] ?? 0;
    if (next < 1 && (next - current).abs() < 0.002) return;
    setState(() => _downloadProgress[key] = next);
  }

  Future<void> _showDownloadCompletion(String key, bool success) async {
    if (!mounted || !_downloadProgress.containsKey(key) || !success) return;
    setState(() => _downloadProgress[key] = 1);
    final motion = context.design.motion;
    await Future<void>.delayed(motion.effective(context, motion.state));
  }

  PreferredSizeWidget _buildAppBar() {
    return ResponsiveAppBar(
      showBack: true,
      title: appLocalizations.dressDetail,
    );
  }
}
