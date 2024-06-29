import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class IToast {
  static FToast show(
    BuildContext context, {
    required String text,
    Icon? icon,
    int seconds = 2,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    FToast toast = FToast().init(context);
    toast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).scaffoldBackgroundColor.withAlpha(240),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 10,
              spreadRadius: 0,
            )
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      gravity: gravity,
      toastDuration: Duration(seconds: seconds),
    );
    return toast;
  }

  static FToast showTop(
    BuildContext context, {
    required String text,
    Icon? icon,
  }) {
    return show(context, text: text, icon: icon);
  }

  static FToast showBottom(
    BuildContext context, {
    required String text,
    Icon? icon,
  }) {
    return show(context, text: text, icon: icon, gravity: ToastGravity.BOTTOM);
  }
}
