import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Models/download_task.dart';
import '../../Utils/download_task_manager.dart';
import '../../l10n/l10n.dart';
import '../Setting/base_setting_screen.dart';

class DownloadManagementScreen extends BaseSettingScreen {
  const DownloadManagementScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = '/download/management';

  @override
  State<DownloadManagementScreen> createState() =>
      _DownloadManagementScreenState();
}

class _DownloadManagementScreenState
    extends BaseDynamicState<DownloadManagementScreen>
    with TickerProviderStateMixin {
  final DownloadTaskManager _manager = DownloadTaskManager.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _manager,
      builder: (context, _) {
        final active = _manager.tasks
            .where((task) => task.isActive)
            .toList(growable: false);
        final history = _manager.tasks
            .where((task) => task.isTerminal)
            .toList(growable: false);
        return ChewieItemBuilder.buildSettingScreen(
          context: context,
          title: appLocalizations.downloadManagement,
          showTitleBar: widget.showTitleBar,
          showBack: !ResponsiveUtil.isLandscapeLayout(),
          padding: widget.padding,
          showBorder: false,
          actions: history.isEmpty
              ? const <Widget>[]
              : <Widget>[
                  IconButton(
                    tooltip: appLocalizations.clearFinishedDownloads,
                    onPressed: _manager.clearFinished,
                    icon: const Icon(LucideIcons.trash2, size: 20),
                  ),
                ],
          overrideBody: _buildBody(active, history),
        );
      },
    );
  }

  Widget _buildBody(
    List<DownloadTask> active,
    List<DownloadTask> history,
  ) {
    if (active.isEmpty && history.isEmpty) {
      return EmptyPlaceholder(
        text: appLocalizations.noDownloadTasks,
        icon: LucideIcons.download,
        shrinkWrap: false,
        topPadding: 120,
      );
    }
    return ListView(
      padding: widget.padding,
      children: [
        if (active.isNotEmpty)
          CaptionItem(
            context: context,
            title: appLocalizations.activeDownloads,
            children: active.map(_buildTask).toList(growable: false),
          ),
        if (history.isNotEmpty)
          CaptionItem(
            context: context,
            title: appLocalizations.downloadHistory,
            children: history.map(_buildTask).toList(growable: false),
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
                    _buildStatusBadge(context),
                  ],
                ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _progressText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChewieTheme.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._buildActions(context),
                  ],
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
          : Icon(
              switch (task.mediaType) {
                DownloadMediaType.image => LucideIcons.image,
                DownloadMediaType.video => LucideIcons.video,
                DownloadMediaType.file => LucideIcons.file,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusText(),
        maxLines: 1,
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
        icon: LucideIcons.pause,
        onTap: onPause,
      ));
    } else if (task.status == DownloadTaskStatus.paused) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.downloading,
        icon: LucideIcons.play,
        onTap: onResume,
      ));
    } else if (task.status == DownloadTaskStatus.failed ||
        task.status == DownloadTaskStatus.cancelled) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.retry,
        icon: LucideIcons.rotateCcw,
        onTap: onRetry,
      ));
    }
    if (task.isActive) {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.cancel,
        icon: LucideIcons.x,
        onTap: onCancel,
      ));
    } else {
      actions.add(_TaskActionButton(
        tooltip: appLocalizations.delete,
        icon: LucideIcons.trash2,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 32,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
