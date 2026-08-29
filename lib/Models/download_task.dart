enum DownloadMediaType {
  image,
  video,
  file;

  static DownloadMediaType fromName(String? value) {
    return DownloadMediaType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DownloadMediaType.file,
    );
  }
}

enum DownloadTaskStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled;

  static DownloadTaskStatus fromName(String? value) {
    return DownloadTaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DownloadTaskStatus.failed,
    );
  }
}

enum DownloadFailureKind {
  network,
  storage,
  server,
  unknown;

  static DownloadFailureKind? fromName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final kind in DownloadFailureKind.values) {
      if (kind.name == value) return kind;
    }
    return DownloadFailureKind.unknown;
  }
}

/// Stable business source for a parent download task.
enum DownloadSourceType {
  postAll,
  collection,
  grain,
  likes,
  recommendations,
  favoriteFolder,
  other;

  static DownloadSourceType fromName(String? value) {
    return DownloadSourceType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => DownloadSourceType.other,
    );
  }
}

class DownloadSourceDescriptor {
  const DownloadSourceDescriptor({
    required this.type,
    required this.sourceId,
    required this.title,
    this.thumbnailUrl,
    this.metadata = const <String, String>{},
  });

  final DownloadSourceType type;
  final String sourceId;
  final String title;
  final String? thumbnailUrl;
  final Map<String, String> metadata;

  String get stableKey => '${type.name}:${sourceId.trim()}';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'sourceId': sourceId,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'metadata': metadata,
      };

  factory DownloadSourceDescriptor.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    return DownloadSourceDescriptor(
      type: DownloadSourceType.fromName(json['type']?.toString()),
      sourceId: json['sourceId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      metadata: rawMetadata is Map
          ? rawMetadata.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
    );
  }
}

enum DownloadGroupStatus {
  queued,
  downloading,
  paused,
  completed,
  partiallyFailed,
  failed,
  cancelled,
}

/// A normalized request that can be submitted alone or as part of a batch.
class DownloadRequest {
  const DownloadRequest({
    required this.url,
    required this.fileName,
    required this.mediaType,
    this.title,
    this.thumbnailUrl,
  });

  final String url;
  final String fileName;
  final String? title;
  final String? thumbnailUrl;
  final DownloadMediaType mediaType;
}

/// Result of one atomic batch enqueue operation.
///
/// Existing active or completed resources are deliberately skipped. Failed,
/// cancelled and paused tasks are requeued so a partial batch can be retried
/// without creating duplicate records or files.
class DownloadBatchResult {
  const DownloadBatchResult({
    required this.requestedCount,
    required this.queuedCount,
    required this.skippedCount,
    required this.invalidCount,
    required this.requeuedCount,
    required this.tasks,
    this.group,
  });

  final int requestedCount;
  final int queuedCount;
  final int skippedCount;
  final int invalidCount;
  final int requeuedCount;
  final List<DownloadTask> tasks;
  final DownloadGroup? group;

  int get newTaskCount => queuedCount - requeuedCount;
}

class DownloadGroup {
  const DownloadGroup({
    required this.id,
    required this.source,
    required this.taskIds,
    required this.requestedCount,
    required this.createdAt,
    required this.updatedAt,
    this.unavailableCount = 0,
    this.skippedCount = 0,
  });

  final String id;
  final DownloadSourceDescriptor source;
  final List<String> taskIds;
  final int requestedCount;
  final int unavailableCount;
  final int skippedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DownloadGroupSnapshot snapshot(Iterable<DownloadTask> allTasks) {
    final taskIdsSet = taskIds.toSet();
    final tasks = allTasks
        .where((task) => taskIdsSet.contains(task.id))
        .toList(growable: false);
    return DownloadGroupSnapshot(group: this, tasks: tasks);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'source': source.toJson(),
        'taskIds': taskIds,
        'requestedCount': requestedCount,
        'unavailableCount': unavailableCount,
        'skippedCount': skippedCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory DownloadGroup.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as num?)?.toInt() ?? 0,
    );
    final rawSource = json['source'];
    return DownloadGroup(
      id: json['id']?.toString() ?? '',
      source: DownloadSourceDescriptor.fromJson(
        rawSource is Map
            ? Map<String, dynamic>.from(rawSource)
            : const <String, dynamic>{},
      ),
      taskIds: (json['taskIds'] as List?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      requestedCount: (json['requestedCount'] as num?)?.toInt() ?? 0,
      unavailableCount: (json['unavailableCount'] as num?)?.toInt() ?? 0,
      skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ??
            createdAt.millisecondsSinceEpoch,
      ),
    );
  }
}

class DownloadGroupSnapshot {
  const DownloadGroupSnapshot({required this.group, required this.tasks});

  final DownloadGroup group;
  final List<DownloadTask> tasks;

  int get completedCount =>
      tasks.where((task) => task.status == DownloadTaskStatus.completed).length;

  int get failedCount => tasks
      .where((task) =>
          task.status == DownloadTaskStatus.failed ||
          task.status == DownloadTaskStatus.cancelled)
      .length;

  bool get isActive => tasks.any((task) => task.isActive);
  bool get isTerminal =>
      tasks.isNotEmpty && tasks.every((task) => task.isTerminal);

  double get progress {
    if (tasks.isEmpty) return 0;
    final total = tasks.fold<double>(0, (sum, task) {
      if (task.status == DownloadTaskStatus.completed) return sum + 1;
      return sum + task.progress.clamp(0.0, 1.0);
    });
    return (total / tasks.length).clamp(0.0, 1.0);
  }

  int get receivedBytes =>
      tasks.fold<int>(0, (sum, task) => sum + task.receivedBytes);
  int get totalBytes =>
      tasks.fold<int>(0, (sum, task) => sum + task.totalBytes);

  DownloadGroupStatus get status {
    if (tasks.isEmpty) return DownloadGroupStatus.failed;
    if (tasks.any((task) => task.status == DownloadTaskStatus.downloading)) {
      return DownloadGroupStatus.downloading;
    }
    if (tasks.any((task) => task.status == DownloadTaskStatus.queued)) {
      return DownloadGroupStatus.queued;
    }
    if (tasks.any((task) => task.status == DownloadTaskStatus.paused)) {
      return DownloadGroupStatus.paused;
    }
    if (completedCount == tasks.length) return DownloadGroupStatus.completed;
    if (completedCount > 0 && failedCount > 0) {
      return DownloadGroupStatus.partiallyFailed;
    }
    if (tasks.every((task) => task.status == DownloadTaskStatus.cancelled)) {
      return DownloadGroupStatus.cancelled;
    }
    return DownloadGroupStatus.failed;
  }
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.mediaType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.thumbnailUrl,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.savedPath,
    this.errorMessage,
    this.failureKind,
  });

  final String id;
  final String url;
  final String fileName;
  final String? title;
  final String? thumbnailUrl;
  final DownloadMediaType mediaType;
  final DownloadTaskStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String? savedPath;
  final String? errorMessage;
  final DownloadFailureKind? failureKind;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive =>
      status == DownloadTaskStatus.queued ||
      status == DownloadTaskStatus.downloading ||
      status == DownloadTaskStatus.paused;

  bool get isTerminal =>
      status == DownloadTaskStatus.completed ||
      status == DownloadTaskStatus.failed ||
      status == DownloadTaskStatus.cancelled;

  DownloadTask copyWith({
    DownloadTaskStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    Object? savedPath = _notSpecified,
    Object? errorMessage = _notSpecified,
    Object? failureKind = _notSpecified,
    DateTime? updatedAt,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      fileName: fileName,
      title: title,
      thumbnailUrl: thumbnailUrl,
      mediaType: mediaType,
      status: status ?? this.status,
      progress: (progress ?? this.progress).clamp(0.0, 1.0).toDouble(),
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      savedPath: identical(savedPath, _notSpecified)
          ? this.savedPath
          : savedPath as String?,
      errorMessage: identical(errorMessage, _notSpecified)
          ? this.errorMessage
          : errorMessage as String?,
      failureKind: identical(failureKind, _notSpecified)
          ? this.failureKind
          : failureKind as DownloadFailureKind?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'url': url,
      'fileName': fileName,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType.name,
      'status': status.name,
      'progress': progress,
      'receivedBytes': receivedBytes,
      'totalBytes': totalBytes,
      'savedPath': savedPath,
      'errorMessage': errorMessage,
      'failureKind': failureKind?.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      (json['createdAt'] as num?)?.toInt() ?? 0,
    );
    return DownloadTask(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'download',
      title: json['title']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      mediaType: DownloadMediaType.fromName(json['mediaType']?.toString()),
      status: DownloadTaskStatus.fromName(json['status']?.toString()),
      progress: ((json['progress'] as num?)?.toDouble() ?? 0)
          .clamp(0.0, 1.0)
          .toDouble(),
      receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      savedPath: json['savedPath']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      failureKind: DownloadFailureKind.fromName(
        json['failureKind']?.toString(),
      ),
      createdAt: createdAt,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ??
            createdAt.millisecondsSinceEpoch,
      ),
    );
  }
}

const Object _notSpecified = Object();
