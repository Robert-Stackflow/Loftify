import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:loftify/Models/recommend_response.dart';
import 'package:video_player/video_player.dart';

typedef LoadMoreVideo = Future<List<CustomVideoController>> Function(
  int index,
  List<CustomVideoController> list,
);

/// TikTokVideoListController是一系列视频的控制器，内部管理了视频控制器数组
/// 提供了预加载/释放/加载更多功能
class VideoListController extends ChangeNotifier {
  VideoListController({
    this.loadMoreCount = 1,
    this.preloadCount = 2,

    /// 设置为0后，任何不在画面内的视频都会被释放
    /// 若不设置为0，安卓将会无法加载第三个开始的视频
    this.disposeCount = 0,
  });

  /// 到第几个触发预加载，例如：1:最后一个，2:倒数第二个
  final int loadMoreCount;

  /// 预加载多少个视频
  final int preloadCount;

  /// 超出多少个，就释放视频
  final int disposeCount;

  /// 提供视频的builder
  LoadMoreVideo? _videoProvider;

  loadIndex(BuildContext context, int target, {bool reload = false}) {
    if (!reload) {
      if (index.value == target) return;
    }
    var oldIndex = index.value;
    var newIndex = target;

    if (!(oldIndex == 0 && newIndex == 0)) {
      playerOfIndex(oldIndex)?.controller.seekTo(Duration.zero);
      // playerOfIndex(oldIndex)?.controller.addListener(_didUpdateValue);
      // playerOfIndex(oldIndex)?.showPauseIcon.addListener(_didUpdateValue);
      playerOfIndex(oldIndex)?.pause();
    }
    playerOfIndex(newIndex)?.controller.addListener(_didUpdateValue);
    playerOfIndex(newIndex)?.showPauseIcon.addListener(_didUpdateValue);
    playerOfIndex(newIndex)?.play();
    for (var i = 0; i < playerList.length; i++) {
      /// 需要释放[disposeCount]之前的视频
      /// i < newIndex - disposeCount 向下滑动时释放视频
      /// i > newIndex + disposeCount 向上滑动，同时避免disposeCount设置为0时失去视频预加载功能
      if (i < newIndex - disposeCount || i > newIndex + max(disposeCount, 2)) {
        playerOfIndex(i)?.controller.removeListener(_didUpdateValue);
        playerOfIndex(i)?.showPauseIcon.removeListener(_didUpdateValue);
        playerOfIndex(i)?.dispose();
        continue;
      }
      if (i > newIndex && i < newIndex + preloadCount) {
        playerOfIndex(i)?.init();
        continue;
      }
    }
    if (playerList.length - newIndex <= loadMoreCount + 1) {
      _videoProvider?.call(newIndex, playerList).then(
        (list) async {
          playerList.addAll(list);
          notifyListeners();
        },
      );
    }

    index.value = target;
  }

  _didUpdateValue() {
    notifyListeners();
  }

  CustomVideoController? playerOfIndex(int index) {
    if (index < 0 || index > playerList.length - 1) {
      return null;
    }
    return playerList[index];
  }

  int get videoCount => playerList.length;

  init({
    required BuildContext context,
    required PageController pageController,
    required List<CustomVideoController> initialList,
    required LoadMoreVideo videoProvider,
    bool loop = false,
  }) async {
    playerList.addAll(initialList);
    _videoProvider = videoProvider;
    pageController.addListener(() {
      var p = pageController.page!;
      if (p % 1 == 0) {
        loadIndex(context, p ~/ 1);
      }
    });
    loadIndex(context, 0, reload: true);
    notifyListeners();
  }

  /// 目前的视频序号
  ValueNotifier<int> index = ValueNotifier<int>(0);

  /// 视频列表
  List<CustomVideoController> playerList = [];

  ///
  CustomVideoController get currentPlayer => playerList[index.value];

  @override
  Future<void> dispose() async {
    for (var player in playerList) {
      player.controller.removeListener(_didUpdateValue);
      player.showPauseIcon.removeListener(_didUpdateValue);
      player.showPauseIcon.dispose();
      await player.dispose();
    }
    playerList = [];
    super.dispose();
  }
}

typedef ControllerSetter<T> = Future<void> Function(T controller);
typedef ControllerBuilder<T> = T Function();

/// 抽象类，作为视频控制器必须实现这些方法
abstract class BaseVideoController<T> {
  /// 获取当前的控制器实例
  T? get controller;

  /// 是否显示暂停按钮
  ValueNotifier<bool> get showPauseIcon;

  /// 加载视频，在init后，应当开始下载视频内容
  Future<void> init({ControllerSetter<T>? afterInit});

  /// 视频销毁，在dispose后，应当释放任何内存资源
  Future<void> dispose();

  /// 播放
  Future<void> play();

  /// 暂停
  Future<void> pause({bool showPauseIcon = false});
}

/// 异步方法并发锁
Completer<void>? _syncLock;

class CustomVideoController extends BaseVideoController<VideoPlayerController> {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _showPauseIcon = ValueNotifier<bool>(false);

  final PostListItem? videoInfo;

  final ControllerBuilder<VideoPlayerController> _builder;
  final ControllerSetter<VideoPlayerController>? _afterInit;

  CustomVideoController({
    this.videoInfo,
    required ControllerBuilder<VideoPlayerController> builder,
    ControllerSetter<VideoPlayerController>? afterInit,
  })  : _builder = builder,
        _afterInit = afterInit;

  @override
  VideoPlayerController get controller {
    _controller ??= _builder.call();
    return _controller!;
  }

  bool get isDispose => _disposeLock != null;

  bool get prepared => _prepared;
  bool _prepared = false;

  Completer<void>? _disposeLock;

  /// 防止异步方法并发
  Future<void> _syncCall(Future Function()? fn) async {
    // 设置同步等待
    var lastCompleter = _syncLock;
    var completer = Completer<void>();
    _syncLock = completer;
    // 等待其他同步任务完成
    await lastCompleter?.future;
    // 主任务
    await fn?.call();
    // 结束
    completer.complete();
  }

  @override
  Future<void> dispose() async {
    if (!prepared) return;
    _prepared = false;
    await controller.dispose();
    _controller = null;
    _disposeLock = Completer<void>();
  }

  @override
  Future<void> init({
    ControllerSetter<VideoPlayerController>? afterInit,
  }) async {
    if (prepared) return;
    await _syncCall(() async {
      await controller.initialize();
      await controller.setLooping(true);
      afterInit ??= _afterInit;
      await afterInit?.call(controller);
      _prepared = true;
    });
    if (_disposeLock != null) {
      _disposeLock?.complete();
      _disposeLock = null;
    }
  }

  @override
  Future<void> pause({bool showPauseIcon = false}) async {
    await init();
    if (!prepared) return;
    if (_disposeLock != null) {
      await _disposeLock?.future;
    }
    await controller.pause();
    _showPauseIcon.value = true;
  }

  @override
  Future<void> play() async {
    await init();
    if (!prepared) return;
    if (_disposeLock != null) {
      await _disposeLock?.future;
    }
    await controller.play();
    _showPauseIcon.value = false;
  }

  @override
  ValueNotifier<bool> get showPauseIcon => _showPauseIcon;
}
