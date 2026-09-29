import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

class DisplayModePreference {
  const DisplayModePreference._();

  static final RegExp _encodedModePattern = RegExp(
    r'^(\d+)x(\d+)@(\d+(?:\.\d+)?)$',
  );

  static String encode(DisplayMode mode) {
    if (isAutomatic(mode)) return 'auto';
    return '${mode.width}x${mode.height}@${mode.refreshRate.toStringAsFixed(3)}';
  }

  static bool isAutomatic(DisplayMode mode) =>
      mode.width == 0 && mode.height == 0 && mode.refreshRate == 0;

  static DisplayMode resolve({
    required List<DisplayMode> modes,
    required DisplayMode activeMode,
    String? encodedMode,
    int legacyIndex = -1,
  }) {
    if (modes.isEmpty) return DisplayMode.auto;

    if (encodedMode != null && encodedMode.isNotEmpty) {
      for (final mode in modes) {
        if (encode(mode) == encodedMode) return mode;
      }

      final savedMode = _decode(encodedMode);
      if (savedMode != null) {
        final sameResolution = modes.where(
          (mode) =>
              !isAutomatic(mode) &&
              mode.width == savedMode.width &&
              mode.height == savedMode.height,
        );
        if (sameResolution.isNotEmpty) {
          final nearest = sameResolution.reduce(
            (best, mode) => (mode.refreshRate - savedMode.refreshRate).abs() <
                    (best.refreshRate - savedMode.refreshRate).abs()
                ? mode
                : best,
          );
          // Android may report the same physical mode as 60, 59.94, or a
          // nearby fractional value after an OS update. Preserve the user's
          // choice instead of silently falling back to the highest rate.
          if ((nearest.refreshRate - savedMode.refreshRate).abs() <= 1) {
            return nearest;
          }
        }
      }
    } else if (legacyIndex >= 0 && legacyIndex < modes.length) {
      return modes[legacyIndex];
    }

    final matchingResolution = modes.where(
      (mode) =>
          !isAutomatic(mode) &&
          mode.width == activeMode.width &&
          mode.height == activeMode.height,
    );
    if (matchingResolution.isNotEmpty) {
      return matchingResolution.reduce(
        (best, mode) => mode.refreshRate > best.refreshRate ? mode : best,
      );
    }

    final concreteModes = modes.where((mode) => !isAutomatic(mode));
    if (concreteModes.isNotEmpty) {
      return concreteModes.reduce((best, mode) {
        final bestPixels = best.width * best.height;
        final modePixels = mode.width * mode.height;
        if (modePixels != bestPixels) {
          return modePixels > bestPixels ? mode : best;
        }
        return mode.refreshRate > best.refreshRate ? mode : best;
      });
    }
    return modes.first;
  }

  static ({int width, int height, double refreshRate})? _decode(
    String encodedMode,
  ) {
    final match = _encodedModePattern.firstMatch(encodedMode);
    if (match == null) return null;
    final width = int.tryParse(match.group(1)!);
    final height = int.tryParse(match.group(2)!);
    final refreshRate = double.tryParse(match.group(3)!);
    if (width == null || height == null || refreshRate == null) return null;
    return (width: width, height: height, refreshRate: refreshRate);
  }

  static List<DisplayMode> ordered(List<DisplayMode> modes) {
    final unique = <String, DisplayMode>{};
    for (final mode in modes) {
      unique.putIfAbsent(encode(mode), () => mode);
    }
    final result = unique.values.toList()
      ..sort((left, right) {
        final leftAuto = isAutomatic(left);
        final rightAuto = isAutomatic(right);
        if (leftAuto != rightAuto) return leftAuto ? -1 : 1;
        final widthOrder = right.width.compareTo(left.width);
        if (widthOrder != 0) return widthOrder;
        final heightOrder = right.height.compareTo(left.height);
        if (heightOrder != 0) return heightOrder;
        return right.refreshRate.compareTo(left.refreshRate);
      });
    return result;
  }

  static String label(
    DisplayMode mode, {
    required String automaticLabel,
  }) {
    if (isAutomatic(mode)) return automaticLabel;
    final roundedRate = mode.refreshRate.roundToDouble();
    final rateLabel = (mode.refreshRate - roundedRate).abs() < 0.01
        ? roundedRate.toInt().toString()
        : mode.refreshRate.toStringAsFixed(2);
    return '${mode.width} × ${mode.height} · $rateLabel Hz';
  }
}

class DisplayModeController {
  const DisplayModeController._();

  static const MethodChannel _channel = MethodChannel(
    'loftify/display_mode',
  );

  static double surfaceRefreshRate(DisplayMode mode) =>
      DisplayModePreference.isAutomatic(mode) ? 0 : mode.refreshRate;

  static Future<void> setPreferredMode(DisplayMode mode) async {
    await FlutterDisplayMode.setPreferredMode(mode);
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setPreferredRefreshRate', {
      'refreshRate': surfaceRefreshRate(mode),
    });
  }
}
