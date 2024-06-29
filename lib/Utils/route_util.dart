import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RouteUtil {
  static pushMaterialRoute(BuildContext context, Widget page) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));
  }

  static pushCupertinoRoute(BuildContext context, Widget page) {
    return Navigator.push(
        context, CupertinoPageRoute(builder: (context) => page));
  }

  static pushFadeRoute(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: page,
          );
        },
      ),
    );
  }
}
