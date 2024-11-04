import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

extension FPS on Duration {
  double get fps => (1000 / inMilliseconds);
}

/// A widget that shows the current FPS.
class ShowFPS extends StatefulWidget {
  /// Where the [ShowFPS] should be positioned.
  final Alignment alignment;

  /// Whether to show the [ShowFPS].
  /// ```dart
  /// ShowFPS(
  ///   visible: !kReleaseMode,
  ///   child: MyHomePage(),
  /// )
  /// ```
  final bool visible;

  /// Will the [ShowFPS] show the chart.
  final bool showChart;

  /// Where the [ShowFPS] should be assigned with a main widget to monitor.
  final Widget child;

  /// The border radius of the [ShowFPS].
  final BoxDecoration? decoration;

  final TextStyle? textStyle;

  const ShowFPS({
    super.key,
    this.alignment = Alignment.topRight,
    this.visible = true,
    this.showChart = true,
    this.decoration,
    this.textStyle,
    required this.child,
  });

  @override
  ShowFPSState createState() => ShowFPSState();
}

class ShowFPSState extends State<ShowFPS> {
  Duration? previous;
  List<Duration> timings = [];
  double chartWidth = 150;
  double chartHeight = 80;
  late int framesToDisplay = chartWidth ~/ 5;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback(update);
    super.initState();
  }

  update(Duration duration) {
    setState(() {
      if (previous != null) {
        timings.add(duration - previous!);
        if (timings.length > framesToDisplay) {
          timings = timings.sublist(timings.length - framesToDisplay - 1);
        }
      }

      previous = duration;
    });

    if (mounted && widget.visible) {
      SchedulerBinding.instance.addPostFrameCallback(update);
    }
  }

  @override
  void didUpdateWidget(covariant ShowFPS oldWidget) {
    if (oldWidget.visible && !widget.visible) {
      previous = null;
    }

    if (!oldWidget.visible && widget.visible) {
      SchedulerBinding.instance.addPostFrameCallback(update);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: widget.alignment,
      children: [
        widget.child,
        if (widget.visible)
          widget.showChart == true
              ? SafeArea(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: chartHeight,
                        width: chartWidth + 17,
                        padding: const EdgeInsets.all(6.0),
                        decoration: widget.decoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (timings.isNotEmpty)
                              Text(
                                'FPS: ${timings.last.fps.toStringAsFixed(0)}',
                                style: widget.textStyle,
                              ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: SizedBox(
                                width: chartWidth,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ...timings.map((timing) {
                                      final p =
                                          (timing.fps / 60).clamp(0.0, 1.0);

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 1.0,
                                        ),
                                        child: Container(
                                          width: 4,
                                          height: p * chartHeight,
                                          decoration: BoxDecoration(
                                            color: Color.lerp(
                                              const Color(0xfff44336),
                                               Colors.transparent,
                                              p,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: widget.decoration,
                        child: timings.isNotEmpty
                            ? Text(
                                "FPS: ${timings.last.fps.toStringAsFixed(0)}",
                                style: widget.textStyle,
                              )
                            : Container(),
                      ),
                    ),
                  ),
                ),
      ],
    );
  }
}
