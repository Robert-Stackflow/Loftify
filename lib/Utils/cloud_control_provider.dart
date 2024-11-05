import 'package:flutter/cupertino.dart';

import '../Models/cloud_control.dart';

LoftifyControlProvider controlProvider = LoftifyControlProvider();

class LoftifyControlProvider with ChangeNotifier {
  LoftifyControl? _cloudControl;

  LoftifyControl get originalCloudControl =>
      (_cloudControl ?? LoftifyControl.defaultCloudControl);

  set originalCloudControl(LoftifyControl? value) {
    _cloudControl = value;
    notifyListeners();
  }

  LoftifyControl? _globalControl;

  LoftifyControl get globalControl =>
      (_globalControl ?? LoftifyControl.defaultCloudControl);

  set globalControl(LoftifyControl? value) {
    _globalControl = value;
    notifyListeners();
  }
}
