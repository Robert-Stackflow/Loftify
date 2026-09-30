import 'dart:async';

import 'package:flutter/material.dart';

/// Playback ticks must not restart the inactivity countdown.
class VideoControlsController extends ChangeNotifier {
  VideoControlsController({this.hideDelay = const Duration(seconds: 4)});

  final Duration hideDelay;
  Timer? _timer;
  bool _visible = true;
  bool _playing = false;
  int _pointers = 0;
  bool get visible => _visible;

  void setPlaying(bool playing) {
    if (_playing == playing) return;
    _playing = playing;
    _restartTimer();
  }

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
    _restartTimer();
  }

  void toggle() {
    if (!_visible) {
      show();
    } else {
      _timer?.cancel();
      _visible = false;
      notifyListeners();
    }
  }

  void pointerDown() {
    _pointers++;
    _timer?.cancel();
  }

  void pointerUp() {
    if (_pointers > 0) _pointers--;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_playing || !_visible || _pointers > 0) return;
    _timer = Timer(hideDelay, () {
      _visible = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class VideoControlsVisibility extends StatelessWidget {
  const VideoControlsVisibility({
    super.key,
    required this.controller,
    required this.child,
  });

  final VideoControlsController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) => IgnorePointer(
          ignoring: !controller.visible,
          child: ExcludeSemantics(
            excluding: !controller.visible,
            child: AnimatedOpacity(
              opacity: controller.visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: child,
            ),
          ),
        ),
      );
}
