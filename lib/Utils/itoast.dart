import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loftify/Utils/route_util.dart';
import 'package:loftify/Utils/utils.dart';

class IToast {
  static FToast show(
    String text, {
    Icon? icon,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    FToast toast = FToast().init(RouteUtil.getRootContext());
    toast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(RouteUtil.getRootContext()).canvasColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(RouteUtil.getRootContext()).shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: 1,
            ).scale(2)
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(RouteUtil.getRootContext()).textTheme.bodyMedium,
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
}
