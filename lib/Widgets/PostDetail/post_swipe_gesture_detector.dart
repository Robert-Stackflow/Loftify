import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// A horizontal drag surface that yields the gesture arena when a pointer
/// starts inside an interactive horizontal child such as an image carousel.
class PostSwipeGestureDetector extends StatelessWidget {
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

  bool _canStartAt(Offset globalPosition) {
    for (final key in excludedRegions) {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        continue;
      }
      final localPosition = renderObject.globalToLocal(globalPosition);
      if ((Offset.zero & renderObject.size).contains(localPosition)) {
        return false;
      }
    }
    return true;
  }

  bool _isEdgeActivation(BuildContext context, Offset globalPosition) {
    if (edgeActivationWidth <= 0) return false;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return false;
    }
    final localPosition = renderObject.globalToLocal(globalPosition);
    return localPosition.dx <= edgeActivationWidth ||
        localPosition.dx >= renderObject.size.width - edgeActivationWidth;
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: behavior,
      gestures: <Type, GestureRecognizerFactory>{
        _PostSwipeHorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _PostSwipeHorizontalDragGestureRecognizer>(
          _PostSwipeHorizontalDragGestureRecognizer.new,
          (recognizer) {
            recognizer
              ..canStartAt = (position) {
                return _isEdgeActivation(context, position) ||
                    _canStartAt(position);
              }
              ..shouldEagerAcceptAt = (position) {
                return _isEdgeActivation(context, position);
              }
              ..onStart = onHorizontalDragStart
              ..onUpdate = onHorizontalDragUpdate
              ..onEnd = onHorizontalDragEnd
              ..onCancel = onHorizontalDragCancel;
          },
        ),
      },
      child: child,
    );
  }
}

class _PostSwipeHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  bool Function(Offset globalPosition)? canStartAt;
  bool Function(Offset globalPosition)? shouldEagerAcceptAt;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!(canStartAt?.call(event.position) ?? true)) return false;
    return super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (shouldEagerAcceptAt?.call(event.position) ?? false) {
      resolve(GestureDisposition.accepted);
    }
  }
}
