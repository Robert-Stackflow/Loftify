import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/download_task.dart';
import '../../Utils/download_task_manager.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import '../Setting/base_setting_screen.dart';
import 'download_group_detail_screen.dart';

class DownloadManagementScreen extends BaseSettingScreen {
  const DownloadManagementScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
    this.manager,
  });

  final DownloadTaskManager? manager;

  static const String routeName = '/download/management';

  @override
  State<DownloadManagementScreen> createState() =>
      _DownloadManagementScreenState();
}

class _DownloadManagementScreenState
    extends BaseDynamicState<DownloadManagementScreen>
    with TickerProviderStateMixin {
  late final DownloadTaskManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager ?? DownloadTaskManager.instance;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final groupSnapshots = _manager.groups
            .map((group) => group.snapshot(_manager.tasks))
            .toList(growable: false);
        final groupedTaskIds =
            _manager.groups.expand((group) => group.taskIds).toSet();
        final standaloneTasks = _manager.tasks
            .where((task) => !groupedTaskIds.contains(task.id))
            .toList(growable: false);
        final activeGroups = groupSnapshots
            .where((snapshot) => snapshot.isActive)
            .toList(growable: false);
        final historyGroups = groupSnapshots
            .where((snapshot) => !snapshot.isActive)
            .toList(growable: false);
        final activeTasks = standaloneTasks
            .where((task) => task.isActive)
            .toList(growable: false);
        final historyTasks = standaloneTasks
            .where((task) => task.isTerminal)
            .toList(growable: false);
        final hasHistory = historyGroups.isNotEmpty || historyTasks.isNotEmpty;
        return ChewieItemBuilder.buildSettingScreen(
          context: context,
          title: appLocalizations.downloadManagement,
          showTitleBar: widget.showTitleBar,
          showBack: !ResponsiveUtil.isLandscapeLayout(),
          padding: widget.padding,
          showBorder: false,
          actions: !hasHistory
              ? const <Widget>[]
              : <Widget>[
                  ChewieIconButton(
                    tooltip: appLocalizations.clearFinishedDownloads,
                    onPressed: _manager.clearFinished,
                    icon: LoftifyIcons.delete,
                  ),
                ],
          overrideBody: _buildBody(
            activeGroups,
            historyGroups,
            activeTasks,
            historyTasks,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    List<DownloadGroupSnapshot> activeGroups,
    List<DownloadGroupSnapshot> historyGroups,
    List<DownloadTask> activeTasks,
    List<DownloadTask> historyTasks,
  ) {
    if (activeGroups.isEmpty &&
        historyGroups.isEmpty &&
        activeTasks.isEmpty &&
        historyTasks.isEmpty) {
      return EmptyPlaceholder(
        text: appLocalizations.noDownloadTasks,
        icon: LoftifyIcons.download,
        shrinkWrap: false,
        topPadding: 120,
      );
    }
    return ListView(
      padding: widget.padding,
      children: [
        if (activeGroups.isNotEmpty || activeTasks.isNotEmpty)
          CaptionItem(
            context: context,
            title: appLocalizations.activeDownloads,
            children: <Widget>[
              ...activeGroups.map(_buildGroup),
              ...activeTasks.map(_buildTask),
            ],
          ),
        if (historyGroups.isNotEmpty || historyTasks.isNotEmpty)
          CaptionItem(
            context: context,
            title: appLocalizations.downloadHistory,
            children: <Widget>[
              ...historyGroups.map(_buildGroup),
              ...historyTasks.map(_buildTask),
            ],
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTask(DownloadTask task) {
    return _DownloadTaskTile(
      task: task,
      onPause: () => _manager.pause(task.id),
      onResume: () => _manager.resume(task.id),
      onCancel: () => _manager.cancel(task.id),
      onRetry: () => _manager.retry(task.id),
      onRemove: () => _manager.remove(task.id),
    );
  }

  Widget _buildGroup(DownloadGroupSnapshot snapshot) {
    return _DownloadGroupTile(
      snapshot: snapshot,
      onTap: () => RouteUtil.pushPanelCupertinoRoute(
        context,
        DownloadGroupDetailScreen(
          groupId: snapshot.group.id,
          manager: _manager,
        ),
      ),
    );
  }
}

class _DownloadGroupTile extends StatelessWidget {
  const _DownloadGroupTile({required this.snapshot, required this.onTap});

  final DownloadGroupSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = _useCompactDownloadTileLayout(context);
    final statusColor = switch (snapshot.status) {
      DownloadGroupStatus.failed ||
      DownloadGroupStatus.partiallyFailed =>
        ChewieTheme.errorColor,
      DownloadGroupStatus.cancelled => scheme.outline,
      _ => scheme.primary,
    };
    final percent = (snapshot.progress * 100).clamp(0, 100).round();
    return InkWell(
      key: ValueKey('download-group-${snapshot.group.id}'),
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAndStatus(
                    context,
                    statusColor,
                    compact: compact,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _sourceTypeText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChewieTheme.labelSmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: snapshot.progress,
                      color: statusColor,
                      backgroundColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    appLocalizations.downloadGroupProgress(
                      snapshot.completedCount,
                      percent,
                      snapshot.tasks.length,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChewieTheme.labelSmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndStatus(
    BuildContext context,
    Color statusColor, {
    required bool compact,
  }) {
    final title = Text(
      snapshot.group.source.title.trim().isEmpty
          ? _sourceTypeText()
          : snapshot.group.source.title.trim(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ChewieTheme.titleSmall.copyWith(
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
    final badge = _buildStatusBadge(context, statusColor);
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: badge),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnailUrl = snapshot.group.source.thumbnailUrl?.trim();
    final canPreview = thumbnailUrl != null && thumbnailUrl.isNotEmpty;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: canPreview
          ? ChewieItemBuilder.buildCachedImage(
              context: context,
              imageUrl: thumbnailUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              showLoading: false,
              simpleError: true,
            )
          : ChewieIcon(
              _sourceIcon,
              size: 21,
              color: scheme.primary,
            ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Color color) {
    return Container(
      key: const ValueKey('download-group-status'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusText(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ChewieTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData get _sourceIcon => switch (snapshot.group.source.type) {
        DownloadSourceType.postAll => LoftifyIcons.article,
        DownloadSourceType.collection => LoftifyIcons.collection,
        DownloadSourceType.grain => LoftifyIcons.grain,
        DownloadSourceType.likes => LoftifyIcons.favorite,
        DownloadSourceType.recommendations => LoftifyIcons.recommend,
        DownloadSourceType.favoriteFolder => LoftifyIcons.favorite,
        DownloadSourceType.other => LoftifyIcons.batchDownload,
      };

  String _sourceTypeText() => switch (snapshot.group.source.type) {
        DownloadSourceType.postAll => appLocalizations.downloadSourcePostAll,
        DownloadSourceType.collection => appLocalizations.collection,
        DownloadSourceType.grain => appLocalizations.grain,
        DownloadSourceType.likes => appLocalizations.myLikes,
        DownloadSourceType.recommendations => appLocalizations.myRecommends,
        DownloadSourceType.favoriteFolder =>
          appLocalizations.downloadSourceFavoriteFolder,
        DownloadSourceType.other => appLocalizations.downloadSourceOther,
      };

  String _statusText() => switch (snapshot.status) {
        DownloadGroupStatus.queued => appLocalizations.waitingForDownload,
        DownloadGroupStatus.downloading => appLocalizations.downloading,
        DownloadGroupStatus.paused => appLocalizations.downloadPaused,
        DownloadGroupStatus.completed => appLocalizations.downloadComplete,
        DownloadGroupStatus.partiallyFailed =>
          appLocalizations.downloadPartiallyFailed,
        DownloadGroupStatus.failed => appLocalizations.downloadFailed,
        DownloadGroupStatus.cancelled => appLocalizations.downloadCancelled,
      };
}

class _DownloadTaskTile extends StatelessWidget {
  const _DownloadTaskTile({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = _useCompactDownloadTileLayout(context);
    final progressColor = task.status == DownloadTaskStatus.failed ||
            task.status == DownloadTaskStatus.cancelled
        ? colorScheme.outlineVariant
        : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaPreview(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleAndStatus(context, compact: compact),
                const SizedBox(height: 5),
                Text(
                  task.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChewieTheme.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: task.totalBytes > 0 ? task.progress : null,
                    color: progressColor,
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 7),
                _buildProgressAndActions(
                  context,
                  compact: compact,
                ),
                if (task.errorMessage?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.errorMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ChewieTheme.labelSmall.copyWith(
                      color: ChewieTheme.errorColor,
                      height: 1.3,
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

  Widget _buildTitleAndStatus(
    BuildContext context, {
    required bool compact,
  }) {
    final title = Text(
      task.title?.trim().isNotEmpty == true
          ? task.title!.trim()
          : task.fileName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: ChewieTheme.titleSmall.copyWith(
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
    final badge = _buildStatusBadge(context);
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: badge),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }

  Widget _buildProgressAndActions(
    BuildContext context, {
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = Text(
      _progressText(),
      maxLines: compact ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: ChewieTheme.labelSmall.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
    final actions = Row(
      key: const ValueKey('download-task-actions'),
      mainAxisSize: MainAxisSize.min,
      children: _buildActions(context),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          progress,
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: progress),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPreview = task.mediaType == DownloadMediaType.image &&
        task.thumbnailUrl?.isNotEmpty == true;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: canPreview
          ? ChewieItemBuilder.buildCachedImage(
              context: context,
              imageUrl: task.thumbnailUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              showLoading: false,
              simpleError: true,
            )
          : ChewieIcon(
              switch (task.mediaType) {
                DownloadMediaType.image => LoftifyIcons.image,
                DownloadMediaType.video => LoftifyIcons.video,
                DownloadMediaType.file => LoftifyIcons.file,
              },
              size: 21,
              color: colorScheme.primary,
            ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = task.status == DownloadTaskStatus.failed;
    final color = isError ? ChewieTheme.errorColor : colorScheme.primary;
    return Container(
      key: const ValueKey('download-task-status'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusText(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ChewieTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    if (task.status == DownloadTaskStatus.downloading ||
        task.status == DownloadTaskStatus.queued) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.downloadPaused,
        icon: LoftifyIcons.pause,
        onTap: onPause,
      ));
    } else if (task.status == DownloadTaskStatus.paused) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.downloading,
        icon: LoftifyIcons.play,
        onTap: onResume,
      ));
    } else if (task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.cancelled) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.retry,
        icon: LoftifyIcons.retry,
        onTap: onRetry,
      ));
    }
    if (task.isActive) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.cancel,
        icon: LoftifyIcons.close,
        onTap: onCancel,
      ));
    } else {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.delete,
        icon: LoftifyIcons.delete,
        onTap: onRemove,
      ));
    }
    return actions;
  }

  String _statusText() {
    return switch (task.status) {
      DownloadTaskStatus.queued => appLocalizations.waitingForDownload,
      DownloadTaskStatus.downloading => appLocalizations.downloading,
      DownloadTaskStatus.paused => appLocalizations.downloadPaused,
      DownloadTaskStatus.completed => appLocalizations.downloadComplete,
      DownloadTaskStatus.failed => appLocalizations.downloadFailed,
      DownloadTaskStatus.cancelled => appLocalizations.downloadCancelled,
    };
  }

  String _progressText() {
    if (task.totalBytes <= 0) return appLocalizations.downloadUnknownSize;
    final percent = (task.progress * 100).clamp(0, 100).round();
    return '${_formatBytes(task.receivedBytes)} / '
        '${_formatBytes(task.totalBytes)} · $percent%';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    final megabytes = kilobytes / 1024;
    if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
    return '${(megabytes / 1024).toStringAsFixed(1)} GB';
  }
}

class _TaskActionButton extends StatelessWidget {
  const _TaskActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ChewieIconButton(
        icon: icon,
        onPressed: onTap,
        tooltip: tooltip,
        style: ChewieIconButtonStyle.soft,
        iconSize: 16,
        cornerRadius: 999,
      ),
    );
  }
}

bool _useCompactDownloadTileLayout(BuildContext context) {
  return MediaQuery.sizeOf(context).width < 380 ||
      MediaQuery.textScalerOf(context).scale(1) > 1.35;
}
