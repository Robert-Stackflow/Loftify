import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'floating_notification.dart';
import 'notification_overlay_widget.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() => _instance;

  NotificationManager._internal();

  NotificationOverlayWidgetState? _overlayState;
  OverlayEntry? _overlayEntry;

  final int maxCount = 3;
  final List<NotificationEntry> _queue = [];

  void attachOverlayState(NotificationOverlayWidgetState state) {
    _overlayState = state;
  }

  void show(
    BuildContext context,
    String message, {
    OverlayState? overlayState,
    String? description,
    Duration duration = const Duration(seconds: 3),
    NotificationStyle? style,
    NotificationType type = NotificationType.normal,
  }) {
    _ensureOverlay(context, overlayState);

    if (_queue.length >= maxCount) {
      _queue.removeAt(0);
    }

    final entry = NotificationEntry(
      key: ValueKey("notify_${DateTime.now().millisecondsSinceEpoch}"),
      message: message,
      description: description,
      duration: duration,
      style: style ?? const NotificationStyle(),
      type: type,
    );

    _queue.add(entry);
    Future.delayed(Duration.zero, () {
      _overlayState?.addNotification(entry);
    });
  }

  void _ensureOverlay(BuildContext context, OverlayState? overlayState) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => const NotificationOverlayWidget(),
    );

    final overlay = overlayState ?? Overlay.maybeOf(context);
    if (overlay == null) {
      _overlayEntry = null;
      return;
    }
    overlay.insert(_overlayEntry!);
  }
}

class NotificationEntry {
  final Key key;
  final String message;
  final String? description;
  final Duration duration;
  final NotificationStyle style;
  final NotificationType type;

  NotificationEntry({
    required this.key,
    required this.message,
    required this.duration,
    this.description,
    this.style = const NotificationStyle(),
    this.type = NotificationType.normal,
  });
}
