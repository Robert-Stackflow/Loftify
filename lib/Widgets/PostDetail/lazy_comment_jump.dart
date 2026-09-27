import 'package:flutter/material.dart';

/// Reveals an anchor inside lazy post content from either side of it.
/// [contentExtent] is the end of the post-content sliver (before recommendations).
Future<void> revealLazyComment({
  required ScrollController controller,
  required GlobalKey anchorKey,
  required bool Function() isActive,
  double? contentExtent,
}) async {
  Future<bool> revealIfMounted() async {
    final anchorContext = anchorKey.currentContext;
    if (anchorContext == null) return false;
    await Scrollable.ensureVisible(
      anchorContext,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    return true;
  }

  if (!isActive() || !controller.hasClients) return;
  if (await revealIfMounted()) return;

  if (contentExtent != null) {
    final position = controller.position;
    final approach = (contentExtent - position.viewportDimension * 0.9)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((position.pixels - approach).abs() >
        position.viewportDimension * 0.25) {
      await controller.animateTo(
        approach,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      if (!isActive()) return;
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  // The anchor is before the recommendation sliver. Once near that boundary,
  // move backward by less than one viewport so the lazy child can mount.
  for (var step = 0; step < 80 && isActive(); step++) {
    if (await revealIfMounted()) return;
    if (!controller.hasClients) return;
    final position = controller.position;
    final direction =
        contentExtent != null || position.pixels > position.maxScrollExtent / 2
            ? -1.0
            : 1.0;
    final target =
        (position.pixels + direction * position.viewportDimension * 0.8)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 45),
      curve: Curves.linear,
    );
    if (!isActive()) return;
    await WidgetsBinding.instance.endOfFrame;
  }
}
