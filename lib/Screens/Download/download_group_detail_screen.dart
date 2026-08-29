import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Models/download_task.dart';
import '../../Utils/download_source_router.dart';
import '../../Utils/download_task_manager.dart';
import '../../Widgets/Design/loftify_controls.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import '../Setting/base_setting_screen.dart';

class DownloadGroupDetailScreen extends BaseSettingScreen {
  const DownloadGroupDetailScreen({
    super.key,
    required this.groupId,
    this.manager,
    super.padding,
    super.showTitleBar,
  });

  final String groupId;
  final DownloadTaskManager? manager;

  static const String routeName = '/download/group-detail';

  @override
  State<DownloadGroupDetailScreen> createState() =>
      _DownloadGroupDetailScreenState();
}

class _DownloadGroupDetailScreenState extends State<DownloadGroupDetailScreen> {
  late final DownloadTaskManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager ?? DownloadTaskManager.instance;
    unawaited(_manager.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final snapshot = _manager.snapshotForGroup(widget.groupId);
        return ChewieItemBuilder.buildSettingScreen(
          context: context,
          title: appLocalizations.downloadTaskDetails,
          showTitleBar: widget.showTitleBar,
          showBack: !ResponsiveUtil.isLandscapeLayout(),
          padding: widget.padding,
          showBorder: false,
          overrideBody: snapshot == null
              ? EmptyPlaceholder(
                  text: appLocalizations.noDownloadTasks,
                  icon: LoftifyIcons.download,
                  shrinkWrap: false,
                  topPadding: 120,
                )
              : _buildBody(snapshot),
        );
      },
    );
  }

  Widget _buildBody(DownloadGroupSnapshot snapshot) {
    return ListView(
      key: const Key('download-group-detail-list'),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.downloadSourceSummary,
          children: [
            _DownloadSourceSummary(
              snapshot: snapshot,
              onOpenOriginal: () => _openOriginal(snapshot.group.source),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.downloadOverallProgress,
          children: [
            _DownloadGroupOverview(
              snapshot: snapshot,
              onPause: () => _manager.pauseGroup(widget.groupId),
              onResume: () => _manager.resumeGroup(widget.groupId),
              onCancel: () => _manager.cancelGroup(widget.groupId),
              onRetryFailed: () => _manager.retryFailedGroup(widget.groupId),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.downloadResourceList,
          children: snapshot.tasks
              .map(
                (task) => _DownloadResourceTile(
                  key: ValueKey('download-resource-${task.id}'),
                  task: task,
                  onPause: () => _manager.pause(task.id),
                  onResume: () => _manager.resume(task.id),
                  onCancel: () => _manager.cancel(task.id),
                  onRetry: () => _manager.retry(task.id),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openOriginal(DownloadSourceDescriptor source) {
    final destination = DownloadSourceRouter.destinationFor(source);
    if (destination == null) {
      IToast.showTop(appLocalizations.downloadSourceUnavailable);
      return;
    }
    RouteUtil.pushPanelCupertinoRoute(context, destination);
  }
}

class _DownloadSourceSummary extends StatelessWidget {
  const _DownloadSourceSummary({
    required this.snapshot,
    required this.onOpenOriginal,
  });

  final DownloadGroupSnapshot snapshot;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final source = snapshot.group.source;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SourcePreview(source: source),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.title.trim().isEmpty
                          ? _sourceTypeText(source.type)
                          : source.title.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.titleSmall.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _sourceTypeText(source.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChewieTheme.labelSmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      appLocalizations.downloadBatchCounts(
                        snapshot.group.requestedCount,
                        snapshot.group.skippedCount,
                        snapshot.group.unavailableCount,
                      ),
                      style: ChewieTheme.labelSmall.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LoftifyButton(
            key: const Key('download-view-original'),
            label: appLocalizations.viewOriginalContent,
            icon: LoftifyIcons.openExternal,
            variant: LoftifyButtonVariant.secondary,
            size: LoftifyButtonSize.compact,
            expand: true,
            onPressed: onOpenOriginal,
          ),
        ],
      ),
    );
  }
}

class _SourcePreview extends StatelessWidget {
  const _SourcePreview({required this.source});

  final DownloadSourceDescriptor source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnail = source.thumbnailUrl?.trim();
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnail != null && thumbnail.isNotEmpty
          ? ChewieItemBuilder.buildCachedImage(
              context: context,
              imageUrl: thumbnail,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              showLoading: false,
              simpleError: true,
            )
          : ChewieIcon(
              _sourceIcon(source.type),
              size: 23,
              color: scheme.primary,
            ),
    );
  }
}

class _DownloadGroupOverview extends StatelessWidget {
  const _DownloadGroupOverview({
    required this.snapshot,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetryFailed,
  });

  final DownloadGroupSnapshot snapshot;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetryFailed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _groupStatusColor(context, snapshot.status);
    final percent = (snapshot.progress * 100).clamp(0, 100).round();
    final hasRunning = snapshot.tasks.any(
      (task) =>
          task.status == DownloadTaskStatus.queued ||
          task.status == DownloadTaskStatus.downloading,
    );
    final hasPaused = snapshot.tasks.any(
      (task) => task.status == DownloadTaskStatus.paused,
    );
    final hasFailed = snapshot.tasks.any(
      (task) =>
          task.status == DownloadTaskStatus.failed ||
          task.status == DownloadTaskStatus.cancelled,
    );
    final hasActive = snapshot.tasks.any((task) => task.isActive);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(
                text: _groupStatusText(snapshot.status),
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appLocalizations.downloadGroupProgress(
                    snapshot.completedCount,
                    percent,
                    snapshot.tasks.length,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChewieTheme.labelSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: snapshot.progress,
              color: statusColor,
              backgroundColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            ),
          ),
          if (snapshot.totalBytes > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${_formatBytes(snapshot.receivedBytes)} / '
              '${_formatBytes(snapshot.totalBytes)}',
              style: ChewieTheme.labelSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (hasRunning || hasPaused || hasFailed || hasActive) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasRunning)
                  LoftifyButton(
                    key: const Key('download-group-pause'),
                    label: appLocalizations.pauseAllDownloads,
                    icon: LoftifyIcons.pause,
                    size: LoftifyButtonSize.compact,
                    variant: LoftifyButtonVariant.secondary,
                    onPressed: onPause,
                  ),
                if (hasPaused)
                  LoftifyButton(
                    key: const Key('download-group-resume'),
                    label: appLocalizations.resumeAllDownloads,
                    icon: LoftifyIcons.play,
                    size: LoftifyButtonSize.compact,
                    variant: LoftifyButtonVariant.tonal,
                    onPressed: onResume,
                  ),
                if (hasFailed)
                  LoftifyButton(
                    key: const Key('download-group-retry'),
                    label: appLocalizations.retryFailedDownloads,
                    icon: LoftifyIcons.retry,
                    size: LoftifyButtonSize.compact,
                    variant: LoftifyButtonVariant.tonal,
                    onPressed: onRetryFailed,
                  ),
                if (hasActive)
                  LoftifyButton(
                    key: const Key('download-group-cancel'),
                    label: appLocalizations.cancelAllDownloads,
                    icon: LoftifyIcons.close,
                    size: LoftifyButtonSize.compact,
                    variant: LoftifyButtonVariant.danger,
                    onPressed: onCancel,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DownloadResourceTile extends StatelessWidget {
  const _DownloadResourceTile({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _taskStatusColor(context, task.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResourcePreview(task: task),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title?.trim().isNotEmpty == true
                            ? task.title!.trim()
                            : task.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ChewieTheme.titleSmall.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      text: _taskStatusText(task.status),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  task.fileName,
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
                    value: task.totalBytes > 0 ? task.progress : null,
                    color: statusColor,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _taskProgressText(task),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChewieTheme.labelSmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ..._actions(),
                  ],
                ),
                if (task.errorMessage?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    task.errorMessage!.trim(),
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

  List<Widget> _actions() {
    return switch (task.status) {
      DownloadTaskStatus.queued || DownloadTaskStatus.downloading => [
          _ResourceActionButton(
            tooltip: appLocalizations.downloadPaused,
            icon: LoftifyIcons.pause,
            onTap: onPause,
          ),
          _ResourceActionButton(
            tooltip: appLocalizations.cancel,
            icon: LoftifyIcons.close,
            onTap: onCancel,
          ),
        ],
      DownloadTaskStatus.paused => [
          _ResourceActionButton(
            tooltip: appLocalizations.resumeAllDownloads,
            icon: LoftifyIcons.play,
            onTap: onResume,
          ),
          _ResourceActionButton(
            tooltip: appLocalizations.cancel,
            icon: LoftifyIcons.close,
            onTap: onCancel,
          ),
        ],
      DownloadTaskStatus.failed || DownloadTaskStatus.cancelled => [
          _ResourceActionButton(
            tooltip: appLocalizations.retry,
            icon: LoftifyIcons.retry,
            onTap: onRetry,
          ),
        ],
      DownloadTaskStatus.completed => const <Widget>[],
    };
  }
}

class _ResourcePreview extends StatelessWidget {
  const _ResourcePreview({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPreview = task.mediaType == DownloadMediaType.image &&
        task.thumbnailUrl?.trim().isNotEmpty == true;
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
              size: 20,
              color: scheme.primary,
            ),
    );
  }
}

class _ResourceActionButton extends StatelessWidget {
  const _ResourceActionButton({
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
        tooltip: tooltip,
        icon: icon,
        onPressed: onTap,
        style: ChewieIconButtonStyle.soft,
        iconSize: 16,
        cornerRadius: 99,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ChewieTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

IconData _sourceIcon(DownloadSourceType type) => switch (type) {
      DownloadSourceType.postAll => LoftifyIcons.article,
      DownloadSourceType.collection => LoftifyIcons.collection,
      DownloadSourceType.grain => LoftifyIcons.grain,
      DownloadSourceType.likes => LoftifyIcons.favorite,
      DownloadSourceType.recommendations => LoftifyIcons.recommend,
      DownloadSourceType.favoriteFolder => LoftifyIcons.favorite,
      DownloadSourceType.other => LoftifyIcons.batchDownload,
    };

String _sourceTypeText(DownloadSourceType type) => switch (type) {
      DownloadSourceType.postAll => appLocalizations.downloadSourcePostAll,
      DownloadSourceType.collection => appLocalizations.collection,
      DownloadSourceType.grain => appLocalizations.grain,
      DownloadSourceType.likes => appLocalizations.myLikes,
      DownloadSourceType.recommendations => appLocalizations.myRecommends,
      DownloadSourceType.favoriteFolder =>
        appLocalizations.downloadSourceFavoriteFolder,
      DownloadSourceType.other => appLocalizations.downloadSourceOther,
    };

String _groupStatusText(DownloadGroupStatus status) => switch (status) {
      DownloadGroupStatus.queued => appLocalizations.waitingForDownload,
      DownloadGroupStatus.downloading => appLocalizations.downloading,
      DownloadGroupStatus.paused => appLocalizations.downloadPaused,
      DownloadGroupStatus.completed => appLocalizations.downloadComplete,
      DownloadGroupStatus.partiallyFailed =>
        appLocalizations.downloadPartiallyFailed,
      DownloadGroupStatus.failed => appLocalizations.downloadFailed,
      DownloadGroupStatus.cancelled => appLocalizations.downloadCancelled,
    };

String _taskStatusText(DownloadTaskStatus status) => switch (status) {
      DownloadTaskStatus.queued => appLocalizations.waitingForDownload,
      DownloadTaskStatus.downloading => appLocalizations.downloading,
      DownloadTaskStatus.paused => appLocalizations.downloadPaused,
      DownloadTaskStatus.completed => appLocalizations.downloadComplete,
      DownloadTaskStatus.failed => appLocalizations.downloadFailed,
      DownloadTaskStatus.cancelled => appLocalizations.downloadCancelled,
    };

Color _groupStatusColor(BuildContext context, DownloadGroupStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    DownloadGroupStatus.completed => ChewieTheme.successColor,
    DownloadGroupStatus.failed ||
    DownloadGroupStatus.partiallyFailed =>
      ChewieTheme.errorColor,
    DownloadGroupStatus.cancelled => scheme.outline,
    _ => scheme.primary,
  };
}

Color _taskStatusColor(BuildContext context, DownloadTaskStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    DownloadTaskStatus.completed => ChewieTheme.successColor,
    DownloadTaskStatus.failed => ChewieTheme.errorColor,
    DownloadTaskStatus.cancelled => scheme.outline,
    _ => scheme.primary,
  };
}

String _taskProgressText(DownloadTask task) {
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
