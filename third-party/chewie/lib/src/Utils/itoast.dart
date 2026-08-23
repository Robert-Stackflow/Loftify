import 'dart:async';

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_notifier/local_notifier.dart';

class IToast {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

  static FToast? show(
    String text, {
    Icon? icon,
    String? decription,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    if (ResponsiveUtil.isDesktop()) {
      NotificationManager().show(
        chewieProvider.rootContext,
        text,
        overlayState: chewieProvider.globalNavigatorState?.overlay,
        description: decription,
        duration: Duration(seconds: seconds),
        style: NotificationStyle(icon: icon?.icon, iconColor: icon?.color),
      );
    } else {
      final overlay = chewieProvider.globalNavigatorState?.overlay;
      if (overlay == null || !overlay.mounted) return null;
      _toastTimer?.cancel();
      _toastEntry?.remove();
      _toastEntry = OverlayEntry(
        builder: (context) => Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              minimum: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              child: Align(
                alignment: gravity == ToastGravity.BOTTOM
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: ChewieTheme.defaultDecoration,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(_toastEntry!);
      _toastTimer = Timer(Duration(seconds: seconds), () {
        _toastEntry?.remove();
        _toastEntry = null;
      });
    }
    return null;
  }

  static FToast? showTop(
    String text, {
    Icon? icon,
    String? decription,
  }) {
    if (text.nullOrEmpty) return null;
    return show(
      text,
      icon: icon,
      decription: decription,
    );
  }

  static FToast? showBottom(
    String text, {
    Icon? icon,
  }) {
    return show(text, icon: icon, gravity: ToastGravity.BOTTOM);
  }

  static LocalNotification? showDesktopNotification(
    String title, {
    String? subTitle,
    String? body,
    List<String> actions = const [],
    Function()? onClick,
    Function(int)? onClickAction,
  }) {
    if (!ResponsiveUtil.isDesktop()) return null;
    var nActions =
        actions.map((e) => LocalNotificationAction(text: e)).toList();
    LocalNotification notification = LocalNotification(
      identifier: StringUtil.generateUid(),
      title: title,
      subtitle: subTitle,
      body: body,
      actions: nActions,
    );
    notification.onShow = () {};
    notification.onClose = (closeReason) {
      switch (closeReason) {
        case LocalNotificationCloseReason.userCanceled:
          break;
        case LocalNotificationCloseReason.timedOut:
          break;
        default:
      }
    };
    notification.onClick = onClick;
    notification.onClickAction = onClickAction;
    notification.show();
    return notification;
  }
}
