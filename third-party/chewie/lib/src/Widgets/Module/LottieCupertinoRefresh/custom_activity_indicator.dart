part of 'lottie_cupertino_refresh.dart';

const double _kDefaultIndicatorRadius = 10.0;

class _CustomActivityIndicator extends StatelessWidget {
  const _CustomActivityIndicator({
    super.key,
    this.color,
    this.animating = true,
    this.radius = _kDefaultIndicatorRadius,
    required this.indicator,
  })  : assert(radius > 0.0),
        progress = 1.0;

  const _CustomActivityIndicator.partiallyRevealed({
    this.color,
    this.radius = _kDefaultIndicatorRadius,
    this.progress = 1.0,
    required this.indicator,
  })  : assert(radius > 0.0),
        assert(progress >= 0.0),
        assert(progress <= 1.0),
        animating = false;

  /// Color of the activity indicator.
  ///
  /// Defaults to color extracted from native iOChewieS.
  final Color? color;

  /// Whether the activity indicator is running its animation.
  ///
  /// Defaults to true.
  final bool animating;

  /// Radius of the spinner widget.
  ///
  /// Defaults to 10px. Must be positive and cannot be null.
  final double radius;

  /// Determines the percentage of spinner ticks that will be shown. Typical usage would
  /// display all ticks, however, this allows for more fine-grained control such as
  /// during pull-to-refresh when the drag-down action shows one tick at a time as
  /// the user continues to drag down.
  ///
  /// Defaults to 1.0. Must be between 0.0 and 1.0 inclusive, and cannot be null.
  final double progress;

  final Widget indicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: radius * 2,
      width: radius * 2,
      child: indicator,
    );
  }
}
