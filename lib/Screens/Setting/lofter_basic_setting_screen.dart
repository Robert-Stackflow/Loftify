import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Api/setting_api.dart';
import '../../Api/user_api.dart';
import '../../Models/account_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class LofterBasicSettingScreen extends BaseSettingScreen {
  const LofterBasicSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/lofterBasic";

  @override
  State<LofterBasicSettingScreen> createState() =>
      _LofterBasicSettingScreenState();
}

class _LofterBasicSettingScreenState
    extends BaseDynamicState<LofterBasicSettingScreen>
    with TickerProviderStateMixin {
  bool acceptGiftFlag = true;
  bool showReturnGiftPreviewImg = true;
  bool appimagestamp = true;
  bool imageprotection = true;
  bool videoprotection = true;
  bool personalRecommend = true;
  FullBlogInfo? blogInfo;
  final EasyRefreshController _refreshController = EasyRefreshController();

  _fetchGiftSetting() async {
    return await SettingApi.getGiftSetting().then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 200) {
          IToast.showTop(value['msg']);
          return IndicatorResult.fail;
        } else {
          acceptGiftFlag = value['data']['acceptGiftFlag'] == 1 ? true : false;
          showReturnGiftPreviewImg =
              value['data']['showReturnGiftPreviewImg'] == 1 ? true : false;
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load gift config", e, t);
        IToast.showTop(appLocalizations.loadGiftSettingFailed);
        return IndicatorResult.fail;
      } finally {
        if (mounted) setState(() {});
      }
    });
  }

  _fetchUserInfo() async {
    if (appProvider.token.isNotEmpty) {
      return await UserApi.getUserInfo().then((value) async {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            AccountResponse accountResponse =
                AccountResponse.fromJson(value['response']);
            imageprotection = accountResponse.appImageProtection;
            appimagestamp = accountResponse.appImageStamp;
            videoprotection = accountResponse.appVideoProtect;
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {
          setState(() {});
        }
      });
    }
    return IndicatorResult.success;
  }

  _fetchMiscInfo() async {
    if (appProvider.token.isNotEmpty) {
      return await UserApi.getMiscInfo().then((value) async {
        try {
          if (value['meta']['status'] != 200) {
            IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
            return IndicatorResult.fail;
          } else {
            personalRecommend =
                value['response']['personalRecommend'] == "1" ? true : false;
            return IndicatorResult.success;
          }
        } catch (e, t) {
          ILogger.error("Failed to load misc config", e, t);
          if (mounted) IToast.showTop(appLocalizations.loadFailed);
          return IndicatorResult.fail;
        } finally {
          if (mounted) setState(() {});
        }
      });
    }
    return IndicatorResult.success;
  }

  _updateCopyRightSetting({
    required CopyRightType copyRightType,
    required bool isClose,
    Function()? onSuccess,
  }) async {
    return await HiveUtil.getUserInfo().then((blogInfo) async {
      return await SettingApi.updateCopyRightSetting(
        copyRightType: copyRightType,
        isClose: isClose,
        blogName: blogInfo!.blogName,
      ).then((value) {
        if (value['meta']['status'] == 200) {
          onSuccess?.call();
          setState(() {});
        } else if (copyRightType == CopyRightType.appimagestamp &&
            value['meta']['status'] == 4212) {
          DialogBuilder.showConfirmDialog(
            context,
            title: appLocalizations.copyrightWatermarkTitle,
            message: appLocalizations.copyrightWatermarkMessage,
            confirmButtonText: appLocalizations.goToEdit,
            cancelButtonText: appLocalizations.editLater,
            onTapConfirm: () {
              UriUtil.launchUrlUri(
                  context, "https://www.lofter.com/theme/${blogInfo.blogName}");
            },
            onTapCancel: () {},
            customDialogType: CustomDialogType.normal,
          );
        } else {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.lofterBasicSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      overrideBody: EasyRefresh.builder(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          var t1 = await _fetchGiftSetting();
          var t2 = await _fetchUserInfo();
          var t3 = await _fetchMiscInfo();
          return t1 == IndicatorResult.success &&
                  t2 == IndicatorResult.success &&
                  t3 == IndicatorResult.success
              ? IndicatorResult.success
              : IndicatorResult.fail;
        },
        triggerAxis: Axis.vertical,
        childBuilder: (_, physics) => ListView(
          physics: physics,
          padding: widget.padding,
          children: [
            CaptionItem(
              context: context,
              title: appLocalizations.basicSetting,
              children: [
                CheckboxItem(
                  value: personalRecommend,
                  context: context,
                  title: appLocalizations.personalizedService,
                  description: appLocalizations.personalizedServiceDescription,
                  onTap: () {
                    SettingApi.updatePersonalRecommendSetting(
                      isEnable: !personalRecommend,
                    ).then((value) {
                      if (value['meta']['status'] == 200) {
                        personalRecommend = !personalRecommend;
                        setState(() {});
                      } else {
                        IToast.showTop(
                            value['meta']['desc'] ?? value['meta']['msg']);
                      }
                    });
                  },
                ),
              ],
            ),
            CaptionItem(
              context: context,
              title: appLocalizations.copyrightProtection,
              children: [
                CheckboxItem(
                  value: appimagestamp,
                  context: context,
                  title: appLocalizations.copyrightWatermark,
                  description: appLocalizations.copyrightWatermarkDescription,
                  onTap: () {
                    _updateCopyRightSetting(
                      copyRightType: CopyRightType.appimagestamp,
                      isClose: appimagestamp,
                      onSuccess: () {
                        appimagestamp = !appimagestamp;
                      },
                    );
                  },
                ),
                CheckboxItem(
                  value: imageprotection,
                  context: context,
                  title: appLocalizations.workProtection,
                  description: appLocalizations.workProtectionDescription,
                  onTap: () {
                    _updateCopyRightSetting(
                      copyRightType: CopyRightType.imageprotection,
                      isClose: imageprotection,
                      onSuccess: () {
                        imageprotection = !imageprotection;
                      },
                    );
                  },
                ),
                CheckboxItem(
                  value: videoprotection,
                  context: context,
                  title: appLocalizations.shareVideoProtection,
                  description: appLocalizations.shareVideoProtectionDescription,
                  onTap: () {
                    _updateCopyRightSetting(
                      copyRightType: CopyRightType.videoprotection,
                      isClose: videoprotection,
                      onSuccess: () {
                        videoprotection = !videoprotection;
                      },
                    );
                  },
                ),
              ],
            ),
            CaptionItem(
              context: context,
              title: appLocalizations.giftSetting,
              children: [
                CheckboxItem(
                  value: acceptGiftFlag,
                  context: context,
                  title: appLocalizations.acceptGift,
                  onTap: () {
                    SettingApi.updateGiftSetting(
                      acceptGiftFlag: !acceptGiftFlag,
                      showReturnGiftPreviewImg: showReturnGiftPreviewImg,
                    ).then((value) {
                      if (value['code'] == 200) {
                        acceptGiftFlag = !acceptGiftFlag;
                        setState(() {});
                      } else {
                        IToast.showTop(value['msg']);
                      }
                    });
                  },
                ),
                CheckboxItem(
                  value: showReturnGiftPreviewImg,
                  context: context,
                  title: appLocalizations.imageBlurPreview,
                  onTap: () {
                    SettingApi.updateGiftSetting(
                      acceptGiftFlag: acceptGiftFlag,
                      showReturnGiftPreviewImg: !showReturnGiftPreviewImg,
                    ).then((value) {
                      if (value['code'] == 200) {
                        showReturnGiftPreviewImg = !showReturnGiftPreviewImg;
                        setState(() {});
                      } else {
                        IToast.showTop(value['msg']);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
