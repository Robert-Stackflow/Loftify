import 'dart:collection';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/foundation.dart';

typedef PagedDataLoader<T, C, M> = Future<PagedDataPage<T, C, M>> Function(
  C cursor,
  bool refresh,
);

typedef PagedMetadataMerger<M> = M? Function(
  M? current,
  M? incoming,
  bool refresh,
);

class PagedDataPage<T, C, M> {
  const PagedDataPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.total,
    this.metadata,
  });

  final List<T> items;
  final C nextCursor;
  final bool hasMore;
  final int? total;
  final M? metadata;
}

class PagedDataException implements Exception {
  const PagedDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Keeps refresh and load-more state consistent across list presentations.
///
/// The cursor is committed only after a successful request. This avoids gaps
/// when a page fails and is retried, while [keyOf] prevents repeated cards when
/// adjacent pages overlap.
class PagedDataController<T, K, C, M> extends ChangeNotifier {
  PagedDataController({
    required C initialCursor,
    required this.keyOf,
    required this.loader,
    this.onError,
    this.metadataMerger,
  })  : _initialCursor = initialCursor,
        _cursor = initialCursor;

  final C _initialCursor;
  final K Function(T item) keyOf;
  final PagedDataLoader<T, C, M> loader;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final PagedMetadataMerger<M>? metadataMerger;

  final List<T> _items = <T>[];
  late final List<T> _itemsView = UnmodifiableListView<T>(_items);
  late C _cursor;
  bool _loading = false;
  bool _noMore = false;
  bool _disposed = false;
  int _generation = 0;
  int? _total;
  M? _metadata;

  List<T> get items => _itemsView;
  bool get loading => _loading;
  bool get noMore => _noMore;
  int? get total => _total;
  M? get metadata => _metadata;
  C get cursor => _cursor;

  Future<IndicatorResult> refresh() => _load(refresh: true);

  Future<IndicatorResult> load() => _load(refresh: false);

  Future<IndicatorResult> _load({required bool refresh}) async {
    if (_loading) return IndicatorResult.none;
    if (!refresh && _noMore) return IndicatorResult.noMore;

    _loading = true;
    final requestGeneration = _generation;
    _notifySafely();
    try {
      final requestCursor = refresh ? _initialCursor : _cursor;
      final page = await loader(requestCursor, refresh);
      if (_disposed || requestGeneration != _generation) {
        return IndicatorResult.none;
      }

      final merged = refresh ? <T>[] : List<T>.of(_items);
      final seenKeys = merged.map(keyOf).toSet();
      var addedCount = 0;
      for (final item in page.items) {
        if (seenKeys.add(keyOf(item))) {
          merged.add(item);
          addedCount++;
        }
      }

      _items
        ..clear()
        ..addAll(merged);
      _cursor = page.nextCursor;
      _total = page.total;
      if (metadataMerger != null) {
        _metadata = metadataMerger!(
          refresh ? null : _metadata,
          page.metadata,
          refresh,
        );
      } else if (page.metadata != null || refresh) {
        _metadata = page.metadata;
      }
      _noMore = !page.hasMore ||
          (_total != null && _items.length >= _total!) ||
          (!refresh && page.items.isNotEmpty && addedCount == 0);

      return !refresh && _noMore
          ? IndicatorResult.noMore
          : IndicatorResult.success;
    } catch (error, stackTrace) {
      if (_disposed || requestGeneration != _generation) {
        return IndicatorResult.none;
      }
      onError?.call(error, stackTrace);
      return IndicatorResult.fail;
    } finally {
      if (!_disposed && requestGeneration == _generation) {
        _loading = false;
        _notifySafely();
      }
    }
  }

  void reset({bool notify = true}) {
    _generation++;
    _items.clear();
    _cursor = _initialCursor;
    _loading = false;
    _noMore = false;
    _total = null;
    _metadata = null;
    if (notify) _notifySafely();
  }

  int removeWhere(
    bool Function(T item) test, {
    C Function(C cursor, int removedCount)? updateCursor,
  }) {
    final previousLength = _items.length;
    _items.removeWhere(test);
    final removedCount = previousLength - _items.length;
    if (removedCount == 0) return 0;

    if (_total != null) {
      _total = (_total! - removedCount).clamp(0, 0x7fffffff);
    }
    if (updateCursor != null) {
      _cursor = updateCursor(_cursor, removedCount);
    }
    _noMore = _total != null ? _items.length >= _total! : _noMore;
    _notifySafely();
    return removedCount;
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _disposed = true;
    super.dispose();
  }
}

List<T> parsePagedDataItems<T>(
  dynamic rawItems,
  T Function(Map<String, dynamic> json) parser, {
  void Function(Object error, StackTrace stackTrace)? onMalformed,
}) {
  if (rawItems is! List) return <T>[];
  final items = <T>[];
  for (final rawItem in rawItems) {
    if (rawItem is! Map) continue;
    try {
      items.add(parser(Map<String, dynamic>.from(rawItem)));
    } catch (error, stackTrace) {
      onMalformed?.call(error, stackTrace);
    }
  }
  return items;
}
