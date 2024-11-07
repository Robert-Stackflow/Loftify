import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loftify/Resources/theme.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:loftify/Utils/responsive_util.dart';
import 'package:loftify/Utils/utils.dart';

import 'app_provider.dart';

class IToast {
  static FToast show(
    String text, {
    Icon? icon,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    FToast toast = FToast().init(rootContext);
    toast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: MyTheme.defaultDecoration,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(rootContext).textTheme.bodyMedium,
        ),
      ),
      gravity: gravity,
      toastDuration: Duration(seconds: seconds),
    );
    return toast;
  }

  static FToast showTop(
    String text, {
    Icon? icon,
  }) {
    return show(text, icon: icon);
  }

  static FToast showBottom(
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
      identifier: Utils.getRandomString(),
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
