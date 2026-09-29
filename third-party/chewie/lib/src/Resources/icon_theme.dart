import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared optical and interaction measurements for Lucide interface icons.
@immutable
class ChewieIconThemeData extends ThemeExtension<ChewieIconThemeData> {
  const ChewieIconThemeData({
    this.smallSize = 16,
    this.regularSize = 20,
    this.largeSize = 24,
    this.minimumTapTarget = 44,
    this.cornerRadius = 10,
    this.disabledOpacity = 0.38,
    this.hoverOpacity = 0.08,
    this.focusOpacity = 0.10,
    this.pressedOpacity = 0.12,
    this.selectedContainerOpacity = 0.12,
  })  : assert(smallSize > 0),
        assert(regularSize > 0),
        assert(largeSize > 0),
        assert(minimumTapTarget >= 44),
        assert(cornerRadius >= 0),
        assert(disabledOpacity >= 0 && disabledOpacity <= 1),
        assert(hoverOpacity >= 0 && hoverOpacity <= 1),
        assert(focusOpacity >= 0 && focusOpacity <= 1),
        assert(pressedOpacity >= 0 && pressedOpacity <= 1),
        assert(
          selectedContainerOpacity >= 0 && selectedContainerOpacity <= 1,
        );

  static const ChewieIconThemeData standard = ChewieIconThemeData();

  final double smallSize;
  final double regularSize;
  final double largeSize;
  final double minimumTapTarget;
  final double cornerRadius;
  final double disabledOpacity;
  final double hoverOpacity;
  final double focusOpacity;
  final double pressedOpacity;
  final double selectedContainerOpacity;

  static ChewieIconThemeData of(BuildContext context) {
    return Theme.of(context).extension<ChewieIconThemeData>() ?? standard;
  }

  @override
  ChewieIconThemeData copyWith({
    double? smallSize,
    double? regularSize,
    double? largeSize,
    double? minimumTapTarget,
    double? cornerRadius,
    double? disabledOpacity,
    double? hoverOpacity,
    double? focusOpacity,
    double? pressedOpacity,
    double? selectedContainerOpacity,
  }) {
    return ChewieIconThemeData(
      smallSize: smallSize ?? this.smallSize,
      regularSize: regularSize ?? this.regularSize,
      largeSize: largeSize ?? this.largeSize,
      minimumTapTarget: minimumTapTarget ?? this.minimumTapTarget,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      hoverOpacity: hoverOpacity ?? this.hoverOpacity,
      focusOpacity: focusOpacity ?? this.focusOpacity,
      pressedOpacity: pressedOpacity ?? this.pressedOpacity,
      selectedContainerOpacity:
          selectedContainerOpacity ?? this.selectedContainerOpacity,
    );
  }

  @override
  ChewieIconThemeData lerp(
    covariant ChewieIconThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    return ChewieIconThemeData(
      smallSize: lerpDouble(smallSize, other.smallSize, t)!,
      regularSize: lerpDouble(regularSize, other.regularSize, t)!,
      largeSize: lerpDouble(largeSize, other.largeSize, t)!,
      minimumTapTarget:
          lerpDouble(minimumTapTarget, other.minimumTapTarget, t)!,
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t)!,
      disabledOpacity: lerpDouble(disabledOpacity, other.disabledOpacity, t)!,
      hoverOpacity: lerpDouble(hoverOpacity, other.hoverOpacity, t)!,
      focusOpacity: lerpDouble(focusOpacity, other.focusOpacity, t)!,
      pressedOpacity: lerpDouble(pressedOpacity, other.pressedOpacity, t)!,
      selectedContainerOpacity: lerpDouble(
        selectedContainerOpacity,
        other.selectedContainerOpacity,
        t,
      )!,
    );
  }
}
