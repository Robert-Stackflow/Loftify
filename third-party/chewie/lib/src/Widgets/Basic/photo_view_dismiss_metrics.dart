import 'dart:math' as math;

/// Pure calculations shared by the photo viewer gesture and its regression
/// tests. Keeping the thresholds here makes the interaction independent from
/// the display refresh rate.
class PhotoViewDismissMetrics {
  const PhotoViewDismissMetrics._();

  static const double minimumDismissDistance = 96;
  static const double minimumFlingDistance = 72;
  static const double dismissVelocity = 900;
  static const double minimumScale = 0.86;

  static double threshold(double viewportHeight) {
    return math.max(minimumDismissDistance, viewportHeight * 0.14);
  }

  static double progress(double distance, double viewportHeight) {
    if (viewportHeight <= 0) return 0;
    return (distance / (viewportHeight * 0.34)).clamp(0.0, 1.0);
  }

  static double scale(double progress) {
    final normalized = progress.clamp(0.0, 1.0);
    return 1 - ((1 - minimumScale) * normalized);
  }

  static double backgroundOpacity(double progress) {
    return 1 - progress.clamp(0.0, 1.0);
  }

  static double contentOpacity(double progress) {
    return 1 - (0.12 * progress.clamp(0.0, 1.0));
  }

  static double appBarOpacity(double progress) {
    return (1 - progress.clamp(0.0, 1.0) * 2.5).clamp(0.0, 1.0);
  }

  static bool shouldDismiss({
    required double distance,
    required double velocity,
    required double viewportHeight,
  }) {
    return distance >= threshold(viewportHeight) ||
        (distance >= minimumFlingDistance && velocity >= dismissVelocity);
  }
}
