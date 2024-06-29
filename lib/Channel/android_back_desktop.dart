import 'package:flutter/services.dart';
import 'package:loftify/Utils/iprint.dart';

class AndroidBackDesktopChannel {
  static const String channel = "android/back/desktop";
  static const String eventBackDesktop = "backDesktop";

  static Future<bool> backToDesktop() async {
    const platform = MethodChannel(channel);
    try {
      await platform.invokeMethod(eventBackDesktop);
    } on PlatformException catch (e) {
      IPrint.debug(e);
    }
    return Future.value(false);
  }
}
