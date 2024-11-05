// {
// "enableApp": true,
// "disableReason": "",
// "switchs": {
// "enableEasterEggs": true,
// "enableOverrideCloudControl": true,
// "enableUpdateFromS3": true
// },
// "contacts": {
// "showTelegramGroup": true,
// "telegramGroupUrl": "https://t.me/Loftify",
// "showQQGroup": true,
// "qqGroupUrl": "https://qm.qq.com/q/2HJ8PC1XcQ",
// "email": "2014027378@qq.com",
// "feedbackBody": "",
// "officialWebsite": "https://apps.cloudchewie.com/loftify",
// "shareText": "Loftify - 简洁的LOFTER第三方APP\nhttps://apps.cloudchewie.com/loftify",
// "downloadPkgsUrl": "https://pkgs.cloudchewie.com/Loftify",
// "repoUrl": "https://github.com/Robert-Stackflow/Loftify",
// "releaseUrl": "https://github.com/Robert-Stackflow/Loftify/releases",
// "issueUrl": "https://github.com/Robert-Stackflow/Loftify/issues"
// },
// "features": {
// "showDress": true,
// "showTagDress": true,
// "image": {
// "showCatutu": true,
// "showDownloadButton": true,
// "showDownloadAllButton": true,
// "showCopyLinkButton": true,
// "showImageQualitySettings": true,
// "showBigImageSettings": true,
// "showVideoDownloadButton": true
// }
// }
// }

import 'package:loftify/Utils/constant.dart' as Constant;

class LoftifyControl {
  final bool? enableApp;
  final String? disableReasonTitle;
  final String? disableReasonMessage;
  final Switchs? switchs;
  final Contacts? contacts;
  final Features? features;

  LoftifyControl({
    required this.enableApp,
    required this.disableReasonTitle,
    required this.disableReasonMessage,
    required this.switchs,
    required this.contacts,
    required this.features,
  });

  bool get enableAppNotNull => enableApp ?? true;

  bool get enableEasterEggs => switchs?.enableEasterEggs ?? true;

  bool get enableUpdateFromS3 => switchs?.enableUpdateFromS3 ?? true;

  bool get showDress => features?.showDress ?? true;

  bool get showTagDress => features?.showTagDress ?? true;

  bool get showCatutu => features?.imageFeatures?.showCatutu ?? true;

  bool get showDownloadButton =>
      features?.imageFeatures?.showDownloadButton ?? true;

  bool get showCopyLinkButton =>
      features?.imageFeatures?.showCopyLinkButton ?? true;

  bool get showImageQualitySettings =>
      features?.imageFeatures?.showImageQualitySettings ?? true;

  bool get showBigImageSettings =>
      features?.imageFeatures?.showBigImageSettings ?? true;

  bool get showVideoDownloadButton =>
      features?.imageFeatures?.showVideoDownloadButton ?? true;

  bool get showTelegramGroup => contacts?.showTelegramGroup ?? true;

  bool get showQQGroup => contacts?.showQQGroup ?? true;

  String get telegramGroupUrl =>
      contacts?.telegramGroupUrl ?? Constant.telegramGroupUrl;

  String get qqGroupUrl => contacts?.qqGroupUrl ?? Constant.qqGroupUrl;

  String get feedbackEmail => contacts?.feedbackEmail ?? Constant.feedbackEmail;

  String get feedbackSubject =>
      contacts?.feedbackSubject ?? Constant.feedbackSubject;

  String get feedbackBody => contacts?.feedbackBody ?? Constant.feedbackBody;

  String get officialWebsite =>
      contacts?.officialWebsite ?? Constant.officialWebsite;

  String get shareText => contacts?.shareText ?? Constant.shareText;

  String get downloadPkgsUrl =>
      contacts?.downloadPkgsUrl ?? Constant.downloadPkgsUrl;

  String get repoUrl => contacts?.repoUrl ?? Constant.repoUrl;

  String get releaseUrl => contacts?.releaseUrl ?? Constant.releaseUrl;

  String get issueUrl => contacts?.issueUrl ?? Constant.issueUrl;

  factory LoftifyControl.fromJson(Map<String, dynamic> json) {
    return LoftifyControl(
      enableApp: json['enableApp'],
      disableReasonTitle: json['disableReasonTitle'],
      disableReasonMessage: json['disableReasonMessage'],
      switchs:
          json['switchs'] == null ? null : Switchs.fromJson(json['switchs']),
      contacts:
          json['contacts'] == null ? null : Contacts.fromJson(json['contacts']),
      features:
          json['features'] == null ? null : Features.fromJson(json['features']),
    );
  }

  Map<String, dynamic> toJson() => {
        "enableApp": enableApp,
        "disableReasonTitle": disableReasonTitle,
        "disableReasonMessage": disableReasonMessage,
        "switchs": switchs?.toJson(),
        "contacts": contacts?.toJson(),
        "features": features?.toJson(),
      };

  static LoftifyControl defaultCloudControl = LoftifyControl(
    enableApp: true,
    disableReasonTitle: "",
    disableReasonMessage: "",
    switchs: Switchs(
      enableEasterEggs: true,
      enableOverrideCloudControl: true,
      enableUpdateFromS3: true,
    ),
    contacts: Contacts(
      showTelegramGroup: true,
      telegramGroupUrl: Constant.telegramGroupUrl,
      showQQGroup: true,
      qqGroupUrl: Constant.qqGroupUrl,
      feedbackEmail: Constant.feedbackEmail,
      feedbackBody: Constant.feedbackBody,
      feedbackSubject: Constant.feedbackSubject,
      issueUrl: Constant.issueUrl,
      repoUrl: Constant.repoUrl,
      officialWebsite: Constant.officialWebsite,
      shareText: Constant.shareText,
      downloadPkgsUrl: Constant.downloadPkgsUrl,
      releaseUrl: Constant.releaseUrl,
    ),
    features: Features(
      showDress: true,
      showTagDress: true,
      imageFeatures: ImageFeatures(
        showCatutu: true,
        showDownloadButton: true,
        showCopyLinkButton: true,
        showImageQualitySettings: true,
        showBigImageSettings: true,
        showVideoDownloadButton: true,
      ),
    ),
  );

  static LoftifyControl getOverridedCloudControl(LoftifyControl cloudControl) {
    LoftifyControl control = defaultCloudControl;
    control.contacts!.qqGroupUrl = cloudControl.contacts?.qqGroupUrl;
    control.contacts!.telegramGroupUrl =
        cloudControl.contacts?.telegramGroupUrl;
    control.contacts!.shareText = cloudControl.contacts?.shareText;
    control.contacts!.officialWebsite = cloudControl.contacts?.officialWebsite;
    control.contacts!.downloadPkgsUrl = cloudControl.contacts?.downloadPkgsUrl;
    control.contacts!.feedbackEmail = cloudControl.contacts?.feedbackEmail;
    control.contacts!.feedbackBody = cloudControl.contacts?.feedbackBody;
    control.contacts!.feedbackSubject = cloudControl.contacts?.feedbackSubject;
    control.contacts!.issueUrl = cloudControl.contacts?.issueUrl;
    control.contacts!.repoUrl = cloudControl.contacts?.repoUrl;
    control.contacts!.releaseUrl = cloudControl.contacts?.releaseUrl;
    return control;
  }
}

class Switchs {
  final bool? enableEasterEggs;
  final bool? enableOverrideCloudControl;
  final bool? enableUpdateFromS3;

  Switchs({
    required this.enableEasterEggs,
    required this.enableOverrideCloudControl,
    required this.enableUpdateFromS3,
  });

  factory Switchs.fromJson(Map<String, dynamic> json) {
    return Switchs(
      enableEasterEggs: json['enableEasterEggs'],
      enableOverrideCloudControl: json['enableOverrideCloudControl'],
      enableUpdateFromS3: json['enableUpdateFromS3'],
    );
  }

  Map<String, dynamic> toJson() => {
        "enableEasterEggs": enableEasterEggs,
        "enableOverrideCloudControl": enableOverrideCloudControl,
        "enableUpdateFromS3": enableUpdateFromS3,
      };
}

class Contacts {
  bool? showTelegramGroup;
  bool? showQQGroup;
  String? telegramGroupUrl;
  String? qqGroupUrl;
  String? feedbackEmail;
  String? feedbackSubject;
  String? feedbackBody;
  String? officialWebsite;
  String? shareText;
  String? downloadPkgsUrl;
  String? repoUrl;
  String? releaseUrl;
  String? issueUrl;

  Contacts({
    required this.showTelegramGroup,
    required this.telegramGroupUrl,
    required this.showQQGroup,
    required this.qqGroupUrl,
    required this.feedbackEmail,
    required this.feedbackSubject,
    required this.feedbackBody,
    required this.officialWebsite,
    required this.shareText,
    required this.downloadPkgsUrl,
    required this.repoUrl,
    required this.releaseUrl,
    required this.issueUrl,
  });

  factory Contacts.fromJson(Map<String, dynamic> json) {
    return Contacts(
      showTelegramGroup: json['showTelegramGroup'],
      telegramGroupUrl: json['telegramGroupUrl'],
      showQQGroup: json['showQQGroup'],
      qqGroupUrl: json['qqGroupUrl'],
      feedbackEmail: json['feedbackEmail'],
      feedbackSubject: json['feedbackSubject'],
      feedbackBody: json['feedbackBody'],
      officialWebsite: json['officialWebsite'],
      shareText: json['shareText'],
      downloadPkgsUrl: json['downloadPkgsUrl'],
      repoUrl: json['repoUrl'],
      releaseUrl: json['releaseUrl'],
      issueUrl: json['issueUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        "showTelegramGroup": showTelegramGroup,
        "telegramGroupUrl": telegramGroupUrl,
        "showQQGroup": showQQGroup,
        "qqGroupUrl": qqGroupUrl,
        "feedbackEmail": feedbackEmail,
        "feedbackSubject": feedbackSubject,
        "feedbackBody": feedbackBody,
        "officialWebsite": officialWebsite,
        "shareText": shareText,
        "downloadPkgsUrl": downloadPkgsUrl,
        "repoUrl": repoUrl,
        "releaseUrl": releaseUrl,
        "issueUrl": issueUrl,
      };
}

class Features {
  final bool? showDress;
  final bool? showTagDress;
  final ImageFeatures? imageFeatures;

  Features({
    required this.showDress,
    required this.showTagDress,
    required this.imageFeatures,
  });

  factory Features.fromJson(Map<String, dynamic> json) {
    print("dddddddddddddddddddd:$json");
    return Features(
      showDress: json['showDress'],
      showTagDress: json['showTagDress'],
      imageFeatures: json['imageFeatures'] == null
          ? null
          : ImageFeatures.fromJson(json['imageFeatures']),
    );
  }

  Map<String, dynamic> toJson() => {
        "showDress": showDress,
        "showTagDress": showTagDress,
        "imageFeatures": imageFeatures?.toJson(),
      };
}

class ImageFeatures {
  final bool? showCatutu;
  final bool? showDownloadButton;
  final bool? showCopyLinkButton;
  final bool? showImageQualitySettings;
  final bool? showBigImageSettings;
  final bool? showVideoDownloadButton;

  ImageFeatures({
    required this.showCatutu,
    required this.showDownloadButton,
    required this.showCopyLinkButton,
    required this.showImageQualitySettings,
    required this.showBigImageSettings,
    required this.showVideoDownloadButton,
  });

  factory ImageFeatures.fromJson(Map<String, dynamic> json) {
    return ImageFeatures(
      showCatutu: json['showCatutu'],
      showDownloadButton: json['showDownloadButton'],
      showCopyLinkButton: json['showCopyLinkButton'],
      showImageQualitySettings: json['showImageQualitySettings'],
      showBigImageSettings: json['showBigImageSettings'],
      showVideoDownloadButton: json['showVideoDownloadButton'],
    );
  }

  Map<String, dynamic> toJson() => {
        "showCatutu": showCatutu,
        "showDownloadButton": showDownloadButton,
        "showCopyLinkButton": showCopyLinkButton,
        "showImageQualitySettings": showImageQualitySettings,
        "showBigImageSettings": showBigImageSettings,
        "showVideoDownloadButton": showVideoDownloadButton,
      };
}
