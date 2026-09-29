import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Observes a deliberate horizontal pointer movement without entering the
/// gesture arena. HTML's SelectionArea otherwise wins the arena before the
/// outer post swipe recognizer, making swipes on article text ineffective.
/// Interactive horizontal children can opt out through [excludedRegions].
class PostSwipeGestureDetector extends StatefulWidget {
  const PostSwipeGestureDetector({
    super.key,
    required this.child,
    this.excludedRegions = const <GlobalKey>[],
    this.behavior = HitTestBehavior.translucent,
    this.edgeActivationWidth = 28,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
  });

  final Widget child;
  final List<GlobalKey> excludedRegions;
  final HitTestBehavior behavior;
  final double edgeActivationWidth;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final GestureDragCancelCallback? onHorizontalDragCancel;

  @override
  State<PostSwipeGestureDetector> createState() =>
      _PostSwipeGestureDetectorState();
}

class _PostSwipeGestureDetectorState extends State<PostSwipeGestureDetector> {
  int? _pointer;
  Offset? _start;
  Offset? _last;
  VelocityTracker? _velocity;
  bool _dragging = false;

  bool _canStartAt(Offset globalPosition) {
    if (_isEdge(globalPosition)) return true;
    for (final key in widget.excludedRegions) {
      final region = key.currentContext?.findRenderObject();
      if (region is! RenderBox || !region.attached || !region.hasSize) continue;
      final local = region.globalToLocal(globalPosition);
      if ((Offset.zero & region.size).contains(local)) return false;
    }
    return true;
  }

  bool _isEdge(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (widget.edgeActivationWidth > 0 &&
        renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      final local = renderObject.globalToLocal(globalPosition);
      if (local.dx <= widget.edgeActivationWidth ||
          local.dx >= renderObject.size.width - widget.edgeActivationWidth) {
        return true;
      }
    }
    return false;
  }

  void _onDown(PointerDownEvent event) {
    if (_pointer != null || !_canStartAt(event.position)) return;
    _pointer = event.pointer;
    _start = event.position;
    _last = event.position;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final start = _start!;
    final previous = _last!;
    _last = event.position;
    _velocity?.addPosition(event.timeStamp, event.position);
    var delta = event.position - previous;
    if (!_dragging) {
      final movement = event.position - start;
      if (movement.dx.abs() < 12 ||
          movement.dx.abs() <= movement.dy.abs() * 1.5) {
        return;
      }
      _dragging = true;
      widget.onHorizontalDragStart?.call(DragStartDetails(
        globalPosition: start,
      ));
      // Include movement accumulated before the horizontal intent threshold,
      // otherwise the content visibly lags behind the first accepted frame.
      delta = movement;
    }
    widget.onHorizontalDragUpdate?.call(DragUpdateDetails(
      globalPosition: event.position,
      delta: Offset(delta.dx, 0),
      primaryDelta: delta.dx,
    ));
  }

  void _onUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _velocity?.addPosition(event.timeStamp, event.position);
    if (_dragging) {
      final horizontalVelocity =
          _velocity?.getVelocity().pixelsPerSecond.dx ?? 0.0;
      widget.onHorizontalDragEnd?.call(DragEndDetails(
        velocity: Velocity(pixelsPerSecond: Offset(horizontalVelocity, 0)),
        primaryVelocity: horizontalVelocity,
      ));
    }
    _clear();
  }

  void _onCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    if (_dragging) widget.onHorizontalDragCancel?.call();
    _clear();
  }

  void _clear() {
    _pointer = null;
    _start = null;
    _last = null;
    _velocity = null;
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: widget.behavior,
      gestures: <Type, GestureRecognizerFactory>{
        _EdgePostSwipeRecognizer:
            GestureRecognizerFactoryWithHandlers<_EdgePostSwipeRecognizer>(
          _EdgePostSwipeRecognizer.new,
          (recognizer) => recognizer
            ..isEdge = _isEdge
            ..onStart = (_) {},
        ),
      },
      child: Listener(
        behavior: widget.behavior,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: widget.child,
      ),
    );
  }
}

class _EdgePostSwipeRecognizer extends HorizontalDragGestureRecognizer {
  bool Function(Offset position)? isEdge;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      (isEdge?.call(event.position) ?? false) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
