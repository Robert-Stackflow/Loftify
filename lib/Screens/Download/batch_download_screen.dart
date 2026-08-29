import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/download_task.dart';
import '../../Utils/download_task_manager.dart';
import '../../Utils/enums.dart';
import '../../Utils/post_batch_download_resolver.dart';
import '../../Widgets/PostItem/general_post_item.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'download_management_screen.dart';

typedef LoadAllBatchPosts = Future<List<GeneralPostItem>> Function();

class BatchDownloadScreen extends StatefulWidget {
  const BatchDownloadScreen({
    super.key,
    required this.sourceTitle,
    required this.source,
    required this.initialItems,
    this.loadAllItems,
    this.resolver,
    this.manager,
  });

  final String sourceTitle;
  final DownloadSourceDescriptor source;
  final List<GeneralPostItem> initialItems;
  final LoadAllBatchPosts? loadAllItems;
  final PostBatchDownloadResolver? resolver;
  final DownloadTaskManager? manager;

  @override
  State<BatchDownloadScreen> createState() => _BatchDownloadScreenState();
}

class _BatchDownloadScreenState extends State<BatchDownloadScreen> {
  late final PostBatchDownloadResolver _resolver;
  late final DownloadTaskManager _manager;
  final List<GeneralPostItem> _items = <GeneralPostItem>[];
  final Set<int> _selectedPostIds = <int>{};
  bool _loadingAll = false;
  bool _loadedAll = false;
  bool _resolving = false;
  int _resolvedCount = 0;
  int _resolveTotal = 0;
  DownloadBatchResult? _lastResult;
  int _lastUnavailablePosts = 0;

  @override
  void initState() {
    super.initState();
    _resolver = widget.resolver ?? PostBatchDownloadResolver();
    _manager = widget.manager ?? DownloadTaskManager.instance;
    _replaceItems(widget.initialItems);
    _loadedAll = widget.loadAllItems == null;
  }

  void _replaceItems(Iterable<GeneralPostItem> items) {
    final seen = <int>{};
    _items
      ..clear()
      ..addAll(items.where((item) => item.postId > 0 && seen.add(item.postId)));
    _selectedPostIds.removeWhere((id) => !seen.contains(id));
  }

  List<GeneralPostItem> get _selectableItems => _items
      .where((item) => item.type != PostType.invalid)
      .toList(growable: false);

  bool get _allSelected {
    final selectable = _selectableItems;
    return selectable.isNotEmpty &&
        selectable.every((item) => _selectedPostIds.contains(item.postId));
  }

  Future<void> _toggleAll() async {
    if (_resolving || _loadingAll) return;
    if (_allSelected) {
      setState(_selectedPostIds.clear);
      return;
    }
    if (!_loadedAll && widget.loadAllItems != null) {
      setState(() => _loadingAll = true);
      try {
        final items = await widget.loadAllItems!();
        if (!mounted) return;
        setState(() {
          _replaceItems(items);
          _loadedAll = true;
        });
      } catch (_) {
        if (mounted) IToast.showTop(appLocalizations.loadFailed);
      } finally {
        if (mounted) setState(() => _loadingAll = false);
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedPostIds.addAll(
        _selectableItems.map((item) => item.postId),
      );
      _lastResult = null;
    });
  }

  void _toggleItem(GeneralPostItem item) {
    if (_resolving || item.type == PostType.invalid) return;
    setState(() {
      if (!_selectedPostIds.add(item.postId)) {
        _selectedPostIds.remove(item.postId);
      }
      _lastResult = null;
    });
  }

  Future<void> _submit() async {
    if (_resolving) return;
    final selected = _items
        .where((item) => _selectedPostIds.contains(item.postId))
        .toList(growable: false);
    if (selected.isEmpty) {
      IToast.showTop(appLocalizations.batchDownloadNoSelection);
      return;
    }
    setState(() {
      _resolving = true;
      _resolvedCount = 0;
      _resolveTotal = selected.length;
      _lastResult = null;
      _lastUnavailablePosts = 0;
    });

    final requests = <DownloadRequest>[];
    var unavailablePosts = 0;
    try {
      for (final item in selected) {
        final resolution = await _resolver.resolve(item);
        requests.addAll(resolution.requests);
        if (resolution.failed || resolution.requests.isEmpty) {
          unavailablePosts++;
        }
        if (mounted) setState(() => _resolvedCount++);
      }
      if (requests.isEmpty) {
        if (mounted) {
          IToast.showTop(appLocalizations.noDownloadableResources);
          setState(() => _lastUnavailablePosts = unavailablePosts);
        }
        return;
      }
      final result = await _manager.enqueueBatch(
        requests,
        source: widget.source,
        unavailableCount: unavailablePosts,
      );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _lastUnavailablePosts = unavailablePosts + result.invalidCount;
      });
      IToast.showTop(appLocalizations.batchDownloadSummary(
        _lastUnavailablePosts,
        result.queuedCount,
        result.skippedCount,
      ));
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _openDownloadManager() {
    RouteUtil.pushPanelCupertinoRoute(
      context,
      const DownloadManagementScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildSelectionHeader(),
        Expanded(
          child: _items.isEmpty
              ? EmptyPlaceholder(
                  text: appLocalizations.noArticle,
                  icon: LoftifyIcons.download,
                  shrinkWrap: false,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _BatchPostTile(
                      item: item,
                      selected: _selectedPostIds.contains(item.postId),
                      onTap: () => _toggleItem(item),
                    );
                  },
                ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: ChewieTheme.getBackground(context),
      appBar: ResponsiveAppBar(
        showBack: true,
        title: '${widget.sourceTitle} · ${appLocalizations.batchDownload}',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: body,
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSelectionHeader() {
    final selectedText = appLocalizations.batchDownloadSelected(
      _selectedPostIds.length,
      _selectableItems.length,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: CaptionItem(
        context: context,
        title: selectedText,
        children: [
          CheckboxItem(
            value: _allSelected,
            disabled: _resolving || _loadingAll,
            roundTop: true,
            roundBottom: true,
            title: _loadingAll
                ? appLocalizations.loading
                : appLocalizations.selectAll,
            description: _loadedAll
                ? appLocalizations.batchDownloadRule
                : '${appLocalizations.loadAllPostsForBatch}\n'
                    '${appLocalizations.batchDownloadRule}',
            onTap: _toggleAll,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final scheme = Theme.of(context).colorScheme;
    final result = _lastResult;
    final statusText = _resolving
        ? appLocalizations.batchDownloadResolving(
            _resolvedCount,
            _resolveTotal,
          )
        : result == null
            ? appLocalizations.batchDownloadSelected(
                _selectedPostIds.length,
                _selectableItems.length,
              )
            : appLocalizations.batchDownloadSummary(
                _lastUnavailablePosts,
                result.queuedCount,
                result.skippedCount,
              );
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_resolving)
              LinearProgressIndicator(
                minHeight: 3,
                value: _resolveTotal > 0 ? _resolvedCount / _resolveTotal : 0,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                    width: 0.6,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 500;
                  final status = Text(
                    statusText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ChewieTheme.labelMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  );
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (result != null) ...[
                        RoundIconTextButton(
                          text: appLocalizations.retry,
                          onPressed: _submit,
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        const SizedBox(width: 8),
                      ],
                      RoundIconTextButton(
                        text: result == null
                            ? appLocalizations.download
                            : appLocalizations.downloadManagement,
                        icon: ChewieIcon(
                          LoftifyIcons.download,
                          size: 17,
                          color: Colors.white,
                        ),
                        background: scheme.primary,
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        disabled: _resolving ||
                            (result == null && _selectedPostIds.isEmpty),
                        onPressed:
                            result == null ? _submit : _openDownloadManager,
                      ),
                    ],
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        status,
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: status),
                      const SizedBox(width: 10),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchPostTile extends StatelessWidget {
  const _BatchPostTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GeneralPostItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = item.type == PostType.invalid;
    final imageUrl = item.photoLinks.isNotEmpty
        ? item.photoLinks.first.middle
        : item.firstImageUrl.trim();
    final title = item.processedTitle.isNotEmpty
        ? item.processedTitle
        : disabled
            ? appLocalizations.invalidContent
            : '#${item.postId}';
    return Opacity(
      opacity: disabled ? 0.48 : 1,
      child: InkAnimation(
        borderRadius: BorderRadius.circular(12),
        color: ChewieTheme.cardColor,
        ink: !disabled,
        onTap: disabled ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.38)
                  : scheme.outlineVariant.withValues(alpha: 0.42),
              width: selected ? 1 : 0.6,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(9),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl.startsWith('http') || imageUrl.startsWith('//')
                    ? ChewieItemBuilder.buildCachedImage(
                        context: context,
                        imageUrl: imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        showLoading: false,
                        simpleError: true,
                      )
                    : ChewieIcon(
                        switch (item.type) {
                          PostType.video => LoftifyIcons.video,
                          PostType.article => LoftifyIcons.article,
                          _ => LoftifyIcons.image,
                        },
                        size: 21,
                        color: scheme.primary,
                      ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.titleSmall.copyWith(
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.blogNickName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.labelSmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outline,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const ChewieIcon(
                        LoftifyIcons.check,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
