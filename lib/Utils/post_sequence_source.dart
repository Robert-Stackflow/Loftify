import 'enums.dart';

typedef PostSequenceLoadMore = Future<void> Function();

class PostSequenceEntry {
  const PostSequenceEntry({
    required this.postId,
    required this.blogId,
    required this.blogName,
    required this.type,
  });

  final int postId;
  final int blogId;
  final String blogName;
  final PostType type;

  bool get isNavigable => type == PostType.article || type == PostType.image;
}

class PostSequenceSource {
  PostSequenceSource({PostSequenceLoadMore? loadMore}) : _loadMore = loadMore;

  final PostSequenceLoadMore? _loadMore;
  final List<PostSequenceEntry> _entries = <PostSequenceEntry>[];
  bool _hasMore = false;
  Future<void>? _loadMoreTask;

  List<PostSequenceEntry> get entries => List.unmodifiable(_entries);

  void synchronize(
    Iterable<PostSequenceEntry> entries, {
    required bool hasMore,
  }) {
    final unique = <int, PostSequenceEntry>{};
    for (final entry in entries) {
      if (entry.isNavigable) unique[entry.postId] = entry;
    }
    _entries
      ..clear()
      ..addAll(unique.values);
    _hasMore = hasMore;
  }

  bool canNavigateFrom(int postId, {required bool previous}) {
    final index = _entries.indexWhere((entry) => entry.postId == postId);
    if (index < 0) return false;
    if (previous) return index > 0;
    return index + 1 < _entries.length || _hasMore;
  }

  Future<PostSequenceEntry?> adjacentTo(
    int postId, {
    required bool previous,
  }) async {
    var index = _entries.indexWhere((entry) => entry.postId == postId);
    if (index < 0) return null;
    var target = previous ? index - 1 : index + 1;
    if (target >= 0 && target < _entries.length) return _entries[target];
    if (previous || !_hasMore || _loadMore == null) return null;

    _loadMoreTask ??= _loadMore();
    try {
      await _loadMoreTask;
    } finally {
      _loadMoreTask = null;
    }

    index = _entries.indexWhere((entry) => entry.postId == postId);
    target = index + 1;
    return index >= 0 && target < _entries.length ? _entries[target] : null;
  }
}
