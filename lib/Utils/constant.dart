import 'package:flutter/cupertino.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:loftify/Utils/responsive_util.dart';

import '../generated/l10n.dart';

const defaultPhone = "";
const defaultPassword = "";
const defaultLofterID = "";
const defaultMail = "";

const double maxMediaOrQuoteWidth = 480;

const double searchBarWidth = 400;

const defaultFilenameFormat = "{original_name}";

const double kLoadExtentOffset = 1000;

const Widget emptyWidget = SizedBox.shrink();

const defaultWindowSize = Size(1120, 740);

const minimumSize = Size(630, 700);

const bool defaultEnableSafeMode = true;

const String shareText = "Loftify - 简洁的LOFTER第三方APP\n$officialWebsite";
const String feedbackEmail = "2014027378@qq.com";
const String feedbackSubject = "Loftify反馈";
const windowsKeyPath = r'SOFTWARE\Cloudchewie\Loftify';
const String feedbackBody = "";
const String downloadPkgsUrl = "https://pkgs.cloudchewie.com/Loftify";
const String officialWebsite = "https://apps.cloudchewie.com/loftify";
const String telegramGroupUrl = "https://t.me/Loftify";
const String qqGroupUrl = "https://qm.qq.com/q/2HJ8PC1XcQ";
const String repoUrl = "https://github.com/Robert-Stackflow/Loftify";
const String releaseUrl =
    "https://github.com/Robert-Stackflow/Loftify/releases";
const String issueUrl = "https://github.com/Robert-Stackflow/Loftify/issues";

const String cloudControlUrl =
    "https://apps.cloudchewie.com/loftify/control.json";
const String fontsUrl = "https://apps.cloudchewie.com/loftify/fonts.json";

AndroidAuthMessages androidAuthMessages = AndroidAuthMessages(
  cancelButton: S.current.biometricCancelButton,
  goToSettingsButton: S.current.biometricGoToSettingsButton,
  biometricNotRecognized: S.current.biometricNotRecognized,
  goToSettingsDescription: S.current.biometricGoToSettingsDescription,
  biometricHint: ResponsiveUtil.isWindows()
      ? S.current.biometricReasonWindows("Loftify")
      : S.current.biometricReason("Loftify"),
  biometricSuccess: S.current.biometricSuccess,
  signInTitle: S.current.biometricSignInTitle,
  deviceCredentialsRequiredTitle:
      S.current.biometricDeviceCredentialsRequiredTitle,
);
