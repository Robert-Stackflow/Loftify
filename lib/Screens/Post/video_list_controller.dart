import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:video_player/video_player.dart';

typedef LoadMoreVideo = Future<List<CustomVideoController>> Function(
  int index,
  List<CustomVideoController> list,
);

enum VideoLoadState { idle, initializing, ready, failed }

/// Coordinates the short-video feed. Only the visible item is allowed to play;
/// nearby items are prepared and distant items release their native decoders.
class VideoListController extends ChangeNotifier {
  VideoListController({
    this.loadMoreCount = 1,
    this.preloadCount = 1,
    this.disposeCount = 0,
  });

  final int loadMoreCount;
  final int preloadCount;
  final int disposeCount;

  final ValueNotifier<int> index = ValueNotifier<int>(0);
  final List<CustomVideoController> playerList = [];

  LoadMoreVideo? _videoProvider;
  CustomVideoController? _observedPlayer;
  bool _loadingMore = false;
  bool _canLoadMore = true;
  bool _closed = false;
  int _loadGeneration = 0;

  int get videoCount => playerList.length;

  CustomVideoController? get currentPlayerOrNull => playerOfIndex(index.value);

  CustomVideoController get currentPlayer => currentPlayerOrNull!;

  CustomVideoController? playerOfIndex(int target) {
    if (target < 0 || target >= playerList.length) return null;
    return playerList[target];
  }

  Future<void> init({
    required List<CustomVideoController> initialList,
    required LoadMoreVideo videoProvider,
  }) async {
    if (_closed) return;
    _videoProvider = videoProvider;
    _canLoadMore = true;
    playerList.addAll(initialList);
    notifyListeners();
    if (playerList.isNotEmpty) {
      await loadIndex(0, reload: true);
    }
  }

  Future<void> loadIndex(int target, {bool reload = false}) async {
    if (_closed || playerList.isEmpty) return;
    final safeTarget = target.clamp(0, playerList.length - 1);
    if (!reload && index.value == safeTarget) return;

    final generation = ++_loadGeneration;
    final oldPlayer = currentPlayerOrNull;
    final newPlayer = playerOfIndex(safeTarget);
    index.value = safeTarget;
    _observe(newPlayer);
    notifyListeners();

    if (!identical(oldPlayer, newPlayer)) {
      await oldPlayer?.pause();
      await oldPlayer?.seekToStart();
    }
    if (_closed || generation != _loadGeneration || newPlayer == null) return;

    await newPlayer.play();
    if (_closed || generation != _loadGeneration) {
      await newPlayer.pause();
      return;
    }

    unawaited(_releaseAndPreloadAround(safeTarget, generation));
    _loadMoreIfNeeded(safeTarget);
  }

  Future<void> _releaseAndPreloadAround(int active, int generation) async {
    for (var i = 0; i < playerList.length; i++) {
      if (_closed || generation != _loadGeneration) return;
      final distance = (i - active).abs();
      if (distance > max(disposeCount, preloadCount)) {
        await playerList[i].release();
      } else if (i != active && distance <= preloadCount) {
        await playerList[i].init();
      }
    }
  }

  void _loadMoreIfNeeded(int active) {
    if (_closed || _loadingMore || !_canLoadMore || _videoProvider == null) {
      return;
    }
    if (playerList.length - active > loadMoreCount + 1) return;

    _loadingMore = true;
    unawaited(() async {
      try {
        final additions = await _videoProvider!(active, playerList);
        if (_closed) return;
        final existingIds = playerList
            .map((player) => player.videoInfo?.itemId)
            .whereType<int>()
            .toSet();
        final unique = additions.where((player) {
          final itemId = player.videoInfo?.itemId;
          return itemId == null || existingIds.add(itemId);
        }).toList();
        if (unique.isEmpty) {
          _canLoadMore = false;
          for (final player in additions) {
            await player.close();
          }
        } else {
          playerList.addAll(unique);
          notifyListeners();
        }
      } catch (error) {
        debugPrint('Failed to load more videos: $error');
      } finally {
        _loadingMore = false;
      }
    }());
  }

  void _observe(CustomVideoController? player) {
    if (identical(_observedPlayer, player)) return;
    _observedPlayer?.revision.removeListener(_didUpdateValue);
    _observedPlayer = player;
    _observedPlayer?.revision.addListener(_didUpdateValue);
  }

  void _didUpdateValue() {
    if (!_closed) notifyListeners();
  }

  Future<void> pauseCurrent({bool showPauseIcon = false}) async {
    await currentPlayerOrNull?.pause(showPauseIcon: showPauseIcon);
  }

  Future<void> resumeCurrent() async {
    await currentPlayerOrNull?.play();
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _loadGeneration++;
    _observedPlayer?.revision.removeListener(_didUpdateValue);
    _observedPlayer = null;
    for (final player in playerList) {
      unawaited(player.close());
    }
    playerList.clear();
    index.dispose();
    super.dispose();
  }
}

typedef ControllerSetter<T> = Future<void> Function(T controller);
typedef ControllerBuilder<T> = T Function();

abstract class BaseVideoController<T> {
  T? get controllerOrNull;
  ValueNotifier<int> get revision;
  VideoLoadState get loadState;
  bool get prepared;
  Object? get lastError;

  Future<void> init({ControllerSetter<T>? afterInit});
  Future<void> retry({bool autoplay = false});
  Future<void> release();
  Future<void> close();
  Future<void> play();
  Future<void> pause({bool showPauseIcon = false});
}

class CustomVideoController extends BaseVideoController<VideoPlayerController> {
  CustomVideoController({
    this.videoInfo,
    required ControllerBuilder<VideoPlayerController> builder,
    ControllerSetter<VideoPlayerController>? afterInit,
    bool looping = true,
    double playbackSpeed = 1,
  })  : _builder = builder,
        _afterInit = afterInit,
        _looping = looping,
        _playbackSpeed = playbackSpeed;

  final PostListItem? videoInfo;
  final ControllerBuilder<VideoPlayerController> _builder;
  final ControllerSetter<VideoPlayerController>? _afterInit;

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  Future<void> _operationLock = Future<void>.value();
  VideoPlayerController? _controller;
  VideoLoadState _loadState = VideoLoadState.idle;
  Object? _lastError;
  bool _prepared = false;
  bool _showPauseIcon = false;
  bool _closed = false;
  bool _looping;
  double _playbackSpeed;
  int _generation = 0;

  @override
  VideoPlayerController? get controllerOrNull => _controller;

  @override
  ValueNotifier<int> get revision => _revision;

  @override
  VideoLoadState get loadState => _loadState;

  @override
  bool get prepared => _prepared;

  @override
  Object? get lastError => _lastError;

  bool get showPauseIcon => _showPauseIcon;

  bool get isPlaying => _controller?.value.isPlaying ?? false;

  bool get isMuted => (_controller?.value.volume ?? 1) == 0;

  bool get looping => _looping;

  double get playbackSpeed => _playbackSpeed;

  Future<void> _runExclusive(Future<void> Function() operation) {
    final result = _operationLock.then((_) => operation());
    _operationLock = result.catchError((Object _) {});
    return result;
  }

  @override
  Future<void> init({
    ControllerSetter<VideoPlayerController>? afterInit,
  }) {
    return _runExclusive(() async {
      if (_closed || _prepared || _loadState == VideoLoadState.initializing) {
        return;
      }
      final generation = ++_generation;
      _setLoadState(VideoLoadState.initializing);
      _lastError = null;
      final controller = _builder();
      _controller = controller;
      controller.addListener(_handleControllerValue);
      try {
        await controller.initialize();
        if (_closed || generation != _generation) {
          await _disposeController(controller);
          return;
        }
        await controller.setLooping(_looping);
        await controller.setPlaybackSpeed(_playbackSpeed);
        await (afterInit ?? _afterInit)?.call(controller);
        if (_closed || generation != _generation) {
          await _disposeController(controller);
          return;
        }
        _prepared = true;
        _setLoadState(VideoLoadState.ready);
      } catch (error) {
        _lastError = error;
        _prepared = false;
        _setLoadState(VideoLoadState.failed);
        debugPrint('Failed to initialize video: $error');
        await _disposeController(controller);
      }
    });
  }

  @override
  Future<void> retry({bool autoplay = false}) async {
    await release();
    await init();
    if (autoplay && prepared) await play();
  }

  @override
  Future<void> play() async {
    await init();
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.play();
      _showPauseIcon = false;
      _notifyListeners();
    });
  }

  @override
  Future<void> pause({bool showPauseIcon = false}) {
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.pause();
      _showPauseIcon = showPauseIcon;
      _notifyListeners();
    });
  }

  Future<void> seekToStart() async {
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.seekTo(Duration.zero);
    });
  }

  Future<void> toggleMute() async {
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.setVolume(isMuted ? 1 : 0);
      _notifyListeners();
    });
  }

  Future<void> setLooping(bool looping) {
    _looping = looping;
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.setLooping(looping);
      _notifyListeners();
    });
  }

  Future<void> setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.5, 2).toDouble();
    return _runExclusive(() async {
      final controller = _controller;
      if (_closed || !_prepared || controller == null) return;
      await controller.setPlaybackSpeed(_playbackSpeed);
      _notifyListeners();
    });
  }

  @override
  Future<void> release() {
    return _runExclusive(() async {
      _generation++;
      final controller = _controller;
      _controller = null;
      _prepared = false;
      _showPauseIcon = false;
      _lastError = null;
      if (!_closed) _setLoadState(VideoLoadState.idle);
      if (controller != null) await _disposeController(controller);
    });
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    controller.removeListener(_handleControllerValue);
    if (identical(_controller, controller)) _controller = null;
    try {
      await controller.dispose();
    } catch (error) {
      debugPrint('Failed to dispose video controller: $error');
    }
  }

  void _handleControllerValue() {
    final controller = _controller;
    if (_closed || controller == null) return;
    if (controller.value.hasError) {
      _lastError = controller.value.errorDescription;
      _prepared = false;
      _setLoadState(VideoLoadState.failed);
      return;
    }
    _notifyListeners();
  }

  void _setLoadState(VideoLoadState state) {
    if (_loadState == state) return;
    _loadState = state;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_closed) _revision.value++;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    await release();
    _closed = true;
    _generation++;
    _revision.dispose();
  }
}
