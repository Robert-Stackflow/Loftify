import 'dart:io';

import 'package:dio/dio.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/cloud_control_provider.dart';
import 'package:loftify/Utils/constant.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Widgets/Dialog/dialog_builder.dart';

import '../Models/cloud_control.dart';
import '../Utils/ilogger.dart';
import '../Utils/utils.dart';

class ServerApi {
  static Future<LoftifyControl?> getCloudControl() async {
    try {
      final response = await Dio().get(cloudControlUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        var cloudControl = LoftifyControl.fromJson(data);
        ILogger.info(
            "Loaded cloudControl from $cloudControlUrl: ${cloudControl.toJson()}");
        controlProvider.originalCloudControl = cloudControl;
        controlProvider.globalControl = cloudControl;
        if (cloudControl.enableAppNotNull) {
          if (HiveUtil.getBool(HiveUtil.overrideCloudControlKey,
              defaultValue: false)) {
            controlProvider.globalControl =
                LoftifyControl.getOverridedCloudControl(cloudControl);
          }
        } else {
          Utils.initSimpleTray();
          DialogBuilder.showInfoDialog(
            rootContext,
            title: cloudControl.disableReasonTitle,
            message: cloudControl.disableReasonMessage,
            barrierDismissible: false,
            onTapDismiss: () {
              exit(0);
            },
          );
        }
      }
    } catch (e, t) {
      ILogger.error("Failed to load cloudControl from $cloudControlUrl", e, t);
    }
    return null;
  }
}
