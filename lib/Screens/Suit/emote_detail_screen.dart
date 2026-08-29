import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/dress_api.dart';
import 'package:loftify/Models/gift_response.dart';
import 'package:loftify/Screens/Info/nested_mixin.dart';
import 'package:loftify/Utils/hive_util.dart';

import '../../Theme/loftify_design_theme.dart';
import '../../Utils/loftify_file_util.dart';
import '../../Widgets/Design/loftify_download_progress_button.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';

class EmoteDetailScreen extends StatefulWidgetForNested {
  const EmoteDetailScreen({
    super.key,
    required this.emotePackId,
    super.nested = false,
  });

  final int emotePackId;

  static const String routeName = "/info/emoteDetail";

  @override
  State<EmoteDetailScreen> createState() => _EmoteDetailScreenState();
}

class _EmoteDetailScreenState extends BaseDynamicState<EmoteDetailScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GiftEmote? _giftEmote;
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
    userAvatarImg = (await HiveUtil.getUserInfo())?.bigAvaImg;
    return await DressApi.getEmoteDetail(
      emotePackId: widget.emotePackId,
    ).then((value) {
      try {
        if (value['code'] != 200) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          _giftEmote = GiftEmote.fromJson(value['data']['returnGiftEmotePack']);
          _giftEmote!.emoteList
              .sort((a, b) => a.sizeType.compareTo(b.sizeType));
          if (mounted) setState(() {});
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load dress detail", e, t);
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
        _loading = false;
      }
    });
  }

  Future<IndicatorResult> _onRefresh() async {
    return await _fetchDetail(refresh: true);
  }

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
    return WaterfallFlow.builder(
      physics: physics,
      cacheExtent: MediaQuery.sizeOf(context).height,
      padding: const EdgeInsets.all(10),
      itemCount: _giftEmote?.emoteList.length ?? 0,
      gridDelegate: const SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        maxCrossAxisExtent: 300,
      ),
      itemBuilder: (context, index) {
        return _buildItem(_giftEmote!.emoteList[index]);
      },
    );
  }

  Widget _buildItem(EmoteItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: ChewieTheme.canvasColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ChewieItemBuilder.buildHeroCachedImage(
            context: context,
            width: 90,
            height: 90,
            showLoading: false,
            placeholderBackground: Colors.transparent,
            imageUrl: item.url,
          ),
          const SizedBox(height: 10),
          Text(
            item.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            appLocalizations.emote,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: LoftifyDownloadProgressButton(
                  label: appLocalizations.download,
                  icon: LoftifyIcons.download,
                  progress: _downloadProgress[item.url],
                  onPressed: _downloadProgress.containsKey(item.url)
                      ? null
                      : () => _downloadEmote(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadEmote(EmoteItem item) async {
    final key = item.url;
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
      title: appLocalizations.emotePackageDetail,
    );
  }
}
