import 'dart:math' as math;

class PostSwipeGesturePolicy {
  const PostSwipeGesturePolicy._();

  static const double minimumCommitDistance = 72;
  static const double maximumCommitDistance = 128;
  static const double minimumFlingDistance = 36;
  static const double commitVelocity = 900;
  static const double boundaryResistance = 0.22;
  static const double hintRevealStartDistance = 44;
  static const double hintRevealFullDistance = 88;

  static double commitDistance(double viewportWidth) =>
      (viewportWidth * 0.22).clamp(
        minimumCommitDistance,
        maximumCommitDistance,
      );

  static bool hasReachedCommitDistance({
    required double rawOffset,
    required double viewportWidth,
  }) =>
      rawOffset.abs() >= commitDistance(viewportWidth);

  static double visualOffset({
    required double rawOffset,
    required double viewportWidth,
    required bool available,
  }) {
    final maxOffset = math.max(96.0, viewportWidth * 0.42);
    final effective = available ? rawOffset : rawOffset * boundaryResistance;
    return effective.clamp(-maxOffset, maxOffset);
  }

  static double hintRevealProgress(double rawOffset) =>
      ((rawOffset.abs() - hintRevealStartDistance) /
              (hintRevealFullDistance - hintRevealStartDistance))
          .clamp(0, 1);

  static double boundaryHintRevealProgress({
    required double rawOffset,
    required double viewportWidth,
    required bool hasSequenceContext,
  }) {
    if (!hasSequenceContext) return 0;
    return hasReachedCommitDistance(
      rawOffset: rawOffset,
      viewportWidth: viewportWidth,
    )
        ? 1
        : 0;
  }

  static bool shouldCommit({
    required double rawOffset,
    required double velocity,
    required double viewportWidth,
    required bool available,
  }) {
    if (!available) return false;
    if (hasReachedCommitDistance(
      rawOffset: rawOffset,
      viewportWidth: viewportWidth,
    )) {
      return true;
    }
    return rawOffset.abs() >= minimumFlingDistance &&
        velocity.abs() >= commitVelocity &&
        rawOffset.sign == velocity.sign;
  }
}
