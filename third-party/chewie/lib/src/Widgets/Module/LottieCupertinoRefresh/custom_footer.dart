part of 'lottie_cupertino_refresh.dart';

/// Cupertino footer.
/// https://github.com/THEONE10211024/WaterDropListView
class LottieCupertinoFooter extends Footer {
  final Key? key;

  /// Indicator foreground color.
  final Color? foregroundColor;

  /// WaterDrop background color.
  final Color? backgroundColor;

  final double? radius;

  /// Empty widget.
  /// When result is [IndicatorResult.noMore].
  final Widget? emptyWidget;

  final Widget indicator;

  const LottieCupertinoFooter({
    this.key,
    super.triggerOffset = 52,
    super.clamping = false,
    super.position = IndicatorPosition.above,
    super.processedDuration = const Duration(milliseconds: 180),
    super.spring,
    super.readySpringBuilder,
    super.springRebound = true,
    FrictionFactor? frictionFactor,
    super.safeArea,
    super.infiniteOffset = 240,
    super.hitOver,
    super.infiniteHitOver,
    super.hapticFeedback,
    super.triggerWhenRelease,
    super.maxOverOffset = 76,
    this.foregroundColor,
    this.backgroundColor,
    this.emptyWidget,
    required this.indicator,
    this.radius = 18,
  }) : super(
          frictionFactor: frictionFactor ??
              (infiniteOffset == null ? kCustomCupertinoFrictionFactor : null),
          horizontalFrictionFactor: kCustomCupertinoHorizontalFrictionFactor,
        );

  @override
  Widget build(BuildContext context, IndicatorState state) {
    return _CustomIndicator(
      key: key,
      state: state,
      reverse: state.reverse,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      emptyWidget: emptyWidget,
      indicator: indicator,
      radius: radius,
    );
  }
}
