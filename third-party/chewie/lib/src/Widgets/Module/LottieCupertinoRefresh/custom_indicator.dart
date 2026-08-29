part of 'lottie_cupertino_refresh.dart';

const double _kDefaultCustomIndicatorRadius = 20.0;

double kCustomCupertinoFrictionFactor(double overscrollFraction) =>
    0.25 * math.pow(1 - overscrollFraction, 2);

double kCustomCupertinoHorizontalFrictionFactor(double overscrollFraction) =>
    0.52 * math.pow(1 - overscrollFraction, 2);

/// Custom indicator.
/// Base widget for [LottieCupertinoHeader] and [LottieCupertinoFooter].
class _CustomIndicator extends StatefulWidget {
  /// Indicator properties and state.
  final IndicatorState state;

  /// True for up and left.
  /// False for down and right.
  final bool reverse;

  final double? radius;

  /// Indicator foreground color.
  final Color? foregroundColor;

  /// WaterDrop background color.
  final Color? backgroundColor;

  /// Empty widget.
  /// When result is [IndicatorResult.noMore].
  final Widget? emptyWidget;

  final Widget indicator;

  final double indicatorOffset;

  const _CustomIndicator({
    super.key,
    required this.state,
    required this.reverse,
    this.foregroundColor,
    this.backgroundColor,
    this.emptyWidget,
    required this.indicator,
    this.indicatorOffset = 0,
    this.radius,
  });

  @override
  State<_CustomIndicator> createState() => _CustomIndicatorState();
}

class _CustomIndicatorState extends State<_CustomIndicator>
    with SingleTickerProviderStateMixin {
  Axis get _axis => widget.state.axis;

  IndicatorMode get _mode => widget.state.mode;

  double get _offset => widget.state.offset;

  double get _actualTriggerOffset => widget.state.actualTriggerOffset;

  double get _radius => widget.radius ?? _kDefaultCustomIndicatorRadius;

  @override
  void initState() {
    super.initState();
    widget.state.notifier.addModeChangeListener(_onModeChange);
  }

  @override
  void dispose() {
    widget.state.notifier.removeModeChangeListener(_onModeChange);
    super.dispose();
  }

  /// Mode change listener.
  void _onModeChange(IndicatorMode mode, double offset) {
    if (mode == IndicatorMode.ready) {}
  }

  Widget _buildIndicator() {
    final progress =
        (_offset / math.max(1, _actualTriggerOffset)).clamp(0.0, 1.0);
    final availableExtent = math.max(0.0, _offset - 2);
    final fittedScale =
        (availableExtent / math.max(1, _radius * 2)).clamp(0.0, 1.0);
    // Never let the painted indicator become larger than the revealed gap.
    // Otherwise its lower edge is clipped by the returning list and looks as
    // if the content is covering the refresh animation.
    // Keep the visual size on the same proportion as the pull gesture. The
    // fitted cap only protects custom configurations whose trigger distance is
    // smaller than the indicator diameter.
    final scale = math.min(progress, fittedScale);
    Widget indicator;
    switch (_mode) {
      case IndicatorMode.drag:
      case IndicatorMode.armed:
        const Curve opacityCurve = Interval(0.04, 0.72, curve: Curves.easeOut);
        indicator = Opacity(
          key: const ValueKey('indicatorArmed'),
          opacity: opacityCurve.transform(progress),
          child: Transform.scale(
            key: const ValueKey('indicatorPullScale'),
            scale: scale,
            child: _CustomActivityIndicator.partiallyRevealed(
              radius: _radius,
              progress: progress,
              color: widget.foregroundColor,
              indicator: widget.indicator,
            ),
          ),
        );
        break;
      case IndicatorMode.ready:
      case IndicatorMode.processing:
      case IndicatorMode.processed:
        indicator = _CustomActivityIndicator(
          key: const ValueKey('indicatorReady'),
          radius: _radius,
          color: widget.foregroundColor,
          animating: true,
          indicator: widget.indicator,
        );
        break;
      case IndicatorMode.done:
        indicator = _CustomActivityIndicator(
          key: const ValueKey('indicatorDone'),
          radius: _radius * progress,
          color: widget.foregroundColor,
          animating: true,
          indicator: widget.indicator,
        );
        break;
      default:
        indicator = const SizedBox(
          key: ValueKey('indicatorDefault'),
        );
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 120),
      child: widget.state.result == IndicatorResult.noMore
          ? widget.emptyWidget != null
              ? SizedBox(
                  key: const ValueKey('noMoreCustom'),
                  child: widget.emptyWidget!,
                )
              : Icon(
                  ChewieIcons.archive,
                  key: const ValueKey('noMoreDefault'),
                  color: widget.foregroundColor,
                )
          : indicator,
    );
  }

  @override
  Widget build(BuildContext context) {
    double offset = _offset;
    if (widget.state.indicator.infiniteOffset != null &&
        widget.state.indicator.position == IndicatorPosition.locator &&
        (_mode != IndicatorMode.inactive ||
            widget.state.result == IndicatorResult.noMore)) {
      offset = _actualTriggerOffset;
    }
    return Stack(
      key: const ValueKey('refresh-indicator-viewport'),
      alignment: Alignment.center,
      clipBehavior: widget.indicatorOffset == 0 ? Clip.hardEdge : Clip.none,
      children: [
        SizedBox(
          height: _axis == Axis.vertical ? offset : double.infinity,
          width: _axis == Axis.vertical ? double.infinity : offset,
        ),
        // Indicator.
        Positioned.fill(
          child: ColoredBox(
            color: widget.backgroundColor ?? const Color(0x00000000),
            child: Transform.translate(
              offset: _axis == Axis.vertical
                  ? Offset(0, widget.indicatorOffset)
                  : Offset(widget.indicatorOffset, 0),
              child: Align(
                alignment: Alignment.center,
                child: _buildIndicator(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
