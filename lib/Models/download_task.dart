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
      createdAt: createdAt,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ??
            createdAt.millisecondsSinceEpoch,
      ),
    );
  }
}

const Object _notSpecified = Object();
