import 'package:flutter/material.dart';

import 'loftify_icons.dart';

enum LoftifyReactionKind { like, recommend, bookmark }

/// Stable action colors, independent of the user's theme accent.
abstract final class LoftifyReactionColors {
  static const like = Color(0xFFE45B68);
  static const recommend = Color(0xFF4B8FE2);
  static const bookmark = Color(0xFFD99525);

  static Color forKind(LoftifyReactionKind kind) => switch (kind) {
        LoftifyReactionKind.like => like,
        LoftifyReactionKind.recommend => recommend,
        LoftifyReactionKind.bookmark => bookmark,
      };
}

/// Keeps Lucide outlines for the idle state and uses matching, tintable
/// vector silhouettes for persistent selected states.
class LoftifyReactionIcon extends StatelessWidget {
  const LoftifyReactionIcon({
    super.key,
    required this.kind,
    required this.selected,
    this.size = 24,
    this.color,
  });

  final LoftifyReactionKind kind;
  final bool selected;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        (selected
            ? LoftifyReactionColors.forKind(kind)
            : IconTheme.of(context).color ?? Colors.black);
    if (!selected) {
      final icon = switch (kind) {
        LoftifyReactionKind.like => LoftifyIcons.favorite,
        LoftifyReactionKind.recommend => LoftifyIcons.recommend,
        LoftifyReactionKind.bookmark => LoftifyIcons.bookmark,
      };
      return Icon(icon, size: size, color: resolvedColor);
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: LoftifyReactionIconPainter(kind, resolvedColor),
      ),
    );
  }
}

@visibleForTesting
class LoftifyReactionIconPainter extends CustomPainter {
  const LoftifyReactionIconPainter(this.kind, this.color);

  final LoftifyReactionKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    switch (kind) {
      case LoftifyReactionKind.like:
        canvas.drawPath(_heart(), paint);
      case LoftifyReactionKind.recommend:
        canvas.drawPath(_thumb(), paint);
      case LoftifyReactionKind.bookmark:
        canvas.drawPath(_bookmark(), paint);
    }
    canvas.restore();
  }

  Path _heart() => Path()
    ..moveTo(12, 21.3)
    ..cubicTo(10.5, 20, 5.1, 15.3, 3.4, 13.2)
    ..cubicTo(0.9, 10.3, 1.4, 6.7, 3.7, 4.5)
    ..cubicTo(5.9, 2.3, 9.1, 2.5, 11.3, 4.5)
    ..lineTo(12, 5.2)
    ..lineTo(12.7, 4.5)
    ..cubicTo(14.9, 2.5, 18.1, 2.3, 20.3, 4.5)
    ..cubicTo(22.6, 6.7, 23.1, 10.3, 20.6, 13.2)
    ..cubicTo(18.9, 15.3, 13.5, 20, 12, 21.3)
    ..close();

  Path _bookmark() => Path()
    ..moveTo(6, 2.5)
    ..lineTo(18, 2.5)
    ..quadraticBezierTo(20, 2.5, 20, 4.5)
    ..lineTo(20, 21)
    ..quadraticBezierTo(20, 22.1, 19, 21.5)
    ..lineTo(12, 17.5)
    ..lineTo(5, 21.5)
    ..quadraticBezierTo(4, 22.1, 4, 21)
    ..lineTo(4, 4.5)
    ..quadraticBezierTo(4, 2.5, 6, 2.5)
    ..close();

  Path _thumb() => Path()
    ..moveTo(5, 10)
    ..lineTo(8.1, 10)
    ..lineTo(9.6, 8.8)
    ..lineTo(12.1, 3.1)
    ..quadraticBezierTo(12.7, 1.6, 14, 2.2)
    ..quadraticBezierTo(16.7, 3.4, 15.8, 6.4)
    ..lineTo(14.9, 9.6)
    ..lineTo(19.1, 9.6)
    ..quadraticBezierTo(22.4, 9.6, 21.5, 12.9)
    ..lineTo(19.4, 20.1)
    ..quadraticBezierTo(18.9, 21.8, 17.1, 21.8)
    ..lineTo(5, 21.8)
    ..quadraticBezierTo(2.6, 21.8, 2.6, 19.4)
    ..lineTo(2.6, 12.4)
    ..quadraticBezierTo(2.6, 10, 5, 10)
    ..close();

  @override
  bool shouldRepaint(covariant LoftifyReactionIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
