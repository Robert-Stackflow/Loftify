import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Keeps the finite post body and comment preview laid out, so their anchors
/// have exact offsets even off screen. Recommendations remain a separate lazy
/// sliver; they are deliberately not included here.
class PostContentSliver extends StatelessWidget {
  const PostContentSliver({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
}

Future<void> revealPostComment({
  required ScrollController controller,
  required GlobalKey anchorKey,
}) async {
  if (!controller.hasClients) return;
  final anchorContext = anchorKey.currentContext;
  final anchor = anchorContext?.findRenderObject();
  if (anchor == null || !anchor.attached) return;
  final position = controller.position;
  // Only move the post pane, never the recommendations or an outer scrollable.
  if (Scrollable.maybeOf(anchorContext!)?.position != position) return;
  final viewport = RenderAbstractViewport.maybeOf(anchor);
  if (viewport == null) return;
  final target = viewport.getOffsetToReveal(anchor, 0).offset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
  if ((target - position.pixels).abs() < 0.5) return;
  await controller.animateTo(
    target,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );
}
