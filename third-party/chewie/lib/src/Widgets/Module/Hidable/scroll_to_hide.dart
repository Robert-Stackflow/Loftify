/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollToHideController {
  Function()? doShow;
  Function()? doHide;

  void show() {
    doShow?.call();
  }

  void hide() {
    doHide?.call();
  }
}

/// A widget that hides its child when the user scrolls down and shows it again when the user scrolls up.
/// This behavior is commonly used to hide elements like a bottom navigation bar to provide a more immersive user experience.
class ScrollToHide extends StatefulWidget {
  /// Creates a `ScrollToHide` widget.
  ///
  /// The [child], [scrollController], and [height] parameters are required.
  /// The [duration] parameter is optional and defaults to 260 milliseconds.
  ///
  /// The [child] is the widget that you want to hide/show based on the scroll direction.
  ///
  /// The [scrollController] is the `ScrollController` that is connected to the scrollable widget in your app.
  /// This is used to track the scroll position and determine whether to hide or show the child widget.
  ///
  /// The [height] is the initial height of the child widget. When the widget is hidden, its height will be animated to 0.
  const ScrollToHide({
    super.key,
    required this.child,
    required this.scrollController,
    this.duration = const Duration(milliseconds: 260),
    required this.hideDirection,
    this.width,
    this.enabled = true,
    this.height,
    this.controller,
    this.showCurve = Curves.easeOutCubic,
    this.hideCurve = Curves.easeInCubic,
    this.hiddenScale = 0.96,
    this.hiddenOffset = 0.18,
  }) : scrollControllers = const [];

  const ScrollToHide.multi({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    required this.hideDirection,
    this.width,
    this.enabled = true,
    this.height,
    this.controller,
    this.scrollControllers = const [],
    this.showCurve = Curves.easeOutCubic,
    this.hideCurve = Curves.easeInCubic,
    this.hiddenScale = 0.96,
    this.hiddenOffset = 0.18,
  }) : scrollController = null;

  final ScrollToHideController? controller;

  final bool enabled;

  /// The widget that you want to hide/show based on the scroll direction.
  final Widget child;

  /// The `ScrollController` that is connected to the scrollable widget in your app.
  /// This is used to track the scroll position and determine whether to hide or show the child widget.
  final ScrollController? scrollController;

  final List<ScrollController> scrollControllers;

  /// The duration of the animation when the child widget is hidden or shown.
  final Duration duration;

  /// Curves are direction-specific so a returning control can settle softly
  /// while a leaving control gets out of the way without lingering.
  final Curve showCurve;
  final Curve hideCurve;

  /// Small coordinated scale/translation values keep floating controls from
  /// looking as if their height was abruptly clipped to zero.
  final double hiddenScale;
  final double hiddenOffset;

  /// The initial height of the child widget. When the widget is hidden, its height will be animated to 0.
  final double? height;

  /// The initial width of the child widget, its width will be animated to 0 .by providing width you want the hide direction to be horizontal.
  final Axis hideDirection;

  /// The initial width of the child widget, its width will be animated to 0 .by providing width you want the hide direction to be horizontal.
  final double? width;

  @override
  State<ScrollToHide> createState() => ScrollToHideState();
}

class ScrollToHideState extends State<ScrollToHide>
    with SingleTickerProviderStateMixin {
  bool isShown = true;
  late final AnimationController _visibilityController;
  final Map<ScrollController, VoidCallback> _controllerListeners = {};

  List<ScrollController> get _allScrollControllers => [
        if (widget.scrollController != null) widget.scrollController!,
        ...widget.scrollControllers,
      ];

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _replaceScrollControllers(_allScrollControllers);
    widget.controller?.doShow = show;
    widget.controller?.doHide = hide;
  }

  @override
  void dispose() {
    _replaceScrollControllers(const []);
    if (widget.controller?.doShow == show) {
      widget.controller?.doShow = null;
    }
    if (widget.controller?.doHide == hide) {
      widget.controller?.doHide = null;
    }
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _visibilityController.value = isShown ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(ScrollToHide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _visibilityController.duration = widget.duration;
    }
    final newControllers = _controllersFor(widget);
    final controllersChanged = _replaceScrollControllers(newControllers);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?.doShow == show) {
        oldWidget.controller?.doShow = null;
      }
      if (oldWidget.controller?.doHide == hide) {
        oldWidget.controller?.doHide = null;
      }
      widget.controller?.doShow = show;
      widget.controller?.doHide = hide;
    }
    if (oldWidget.enabled && !widget.enabled) show();
    if (controllersChanged) show();
  }

  List<ScrollController> _controllersFor(ScrollToHide target) => [
        if (target.scrollController != null) target.scrollController!,
        ...target.scrollControllers,
      ];

  bool _replaceScrollControllers(List<ScrollController> controllers) {
    final uniqueControllers = <ScrollController>[];
    for (final controller in controllers) {
      if (!uniqueControllers.contains(controller)) {
        uniqueControllers.add(controller);
      }
    }

    var changed = false;
    for (final controller in _controllerListeners.keys.toList()) {
      if (uniqueControllers.contains(controller)) continue;
      controller.removeListener(_controllerListeners.remove(controller)!);
      changed = true;
    }
    for (final controller in uniqueControllers) {
      if (_controllerListeners.containsKey(controller)) continue;
      void listener() => _handleScroll(controller);
      _controllerListeners[controller] = listener;
      controller.addListener(listener);
      changed = true;
    }
    return changed;
  }

  bool get _reduceMotion {
    final mediaQuery = MediaQuery.maybeOf(context);
    return mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.hideDirection == Axis.vertical;
    return AnimatedBuilder(
      key: const ValueKey('scroll-to-hide-transition'),
      animation: _visibilityController,
      builder: (context, child) {
        final progress = _visibilityController.value;
        final scale = widget.hiddenScale + (1 - widget.hiddenScale) * progress;
        final translation = (1 - progress) * widget.hiddenOffset;
        final constrainedChild = SizedBox(
          height: vertical ? widget.height : null,
          width: vertical ? null : widget.width,
          child: Opacity(
            key: const ValueKey('scroll-to-hide-opacity'),
            opacity: progress,
            child: FractionalTranslation(
              translation:
                  vertical ? Offset(0, translation) : Offset(translation, 0),
              child: Transform.scale(
                scale: scale,
                alignment:
                    vertical ? Alignment.bottomCenter : Alignment.centerRight,
                child: child,
              ),
            ),
          ),
        );
        return IgnorePointer(
          ignoring: progress < 0.02,
          child: ClipRect(
            child: Align(
              alignment:
                  vertical ? Alignment.bottomCenter : Alignment.centerRight,
              heightFactor: vertical ? progress : null,
              widthFactor: vertical ? null : progress,
              child: constrainedChild,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }

  /// Shows the child widget if it is currently hidden.
  void show() {
    _setVisibility(true);
  }

  /// Hides the child widget if it is currently shown.
  void hide() {
    _setVisibility(false);
  }

  void _setVisibility(bool shown) {
    if (!mounted || isShown == shown) return;
    isShown = shown;
    final target = shown ? 1.0 : 0.0;
    if (_reduceMotion) {
      _visibilityController.value = target;
      return;
    }
    _visibilityController.animateTo(
      target,
      duration: widget.duration,
      curve: shown ? widget.showCurve : widget.hideCurve,
    );
  }

  void _handleScroll(ScrollController controller) {
    if (!widget.enabled || !controller.hasClients) return;
    final positions = controller.positions.toList(growable: false);
    if (positions.isEmpty) return;
    final position = positions.lastWhere(
      (position) => position.userScrollDirection != ScrollDirection.idle,
      orElse: () => positions.last,
    );
    if (position.pixels <= position.minScrollExtent + 0.5) {
      show();
      return;
    }
    final direction = position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      show();
    } else if (direction == ScrollDirection.reverse) {
      hide();
    }
  }
}
