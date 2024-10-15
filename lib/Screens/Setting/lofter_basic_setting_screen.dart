import 'package:flutter/material.dart';
import 'package:loftify/Utils/uri_util.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';

import '../../Api/setting_api.dart';
import '../../Api/user_api.dart';
import '../../Models/account_response.dart';
import '../../Utils/app_provider.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class LofterBasicSettingScreen extends StatefulWidget {
  const LofterBasicSettingScreen({super.key});

  static const String routeName = "/setting/lofterBasic";

  @override
  State<LofterBasicSettingScreen> createState() =>
      _LofterBasicSettingScreenState();
}

class _LofterBasicSettingScreenState extends State<LofterBasicSettingScreen>
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
      } catch (e,t) {
        ILogger.error("Failed to load gift config", e, t);
        IToast.showTop("礼物设置加载失败");
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
        } catch (e,t) {
          ILogger.error("Failed to load user info", e, t);
          if (mounted) IToast.showTop("加载失败");
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
        } catch (e,t) {
          ILogger.error("Failed to load misc config", e, t);
          if (mounted) IToast.showTop("加载失败");
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
            title: "版权水印关闭提示",
            message: "由于一些历史遗留问题，你需要先在电脑上关闭版权水印功能（主页设置-版权-版权水印）",
            confirmButtonText: "前往更改",
            cancelButtonText: "暂不更改",
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
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildSimpleAppBar(
            title: S.current.lofterBasicSetting,
            context: context,
            transparent: true),
        body: EasyRefresh.builder(
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            children: [
              ItemBuilder.buildRadioItem(
                value: personalRecommend,
                context: context,
                title: "个性化服务",
                topRadius: true,
                bottomRadius: true,
                description: "取消勾选后，将不会使用你的个性信息为你提供个性化服务",
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
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "版权保护"),
              ItemBuilder.buildRadioItem(
                value: appimagestamp,
                context: context,
                title: "版权水印签名",
                description: "勾选后，所有用户保存你的图片到手机，会显示你的签名水印，保护原创",
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
              ItemBuilder.buildRadioItem(
                value: imageprotection,
                context: context,
                title: "作品保护",
                description: "勾选后,发布的图片日志将禁止被保存到本地",
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
              ItemBuilder.buildRadioItem(
                value: videoprotection,
                context: context,
                bottomRadius: true,
                title: "生成分享视频",
                description: "勾选后，你的作品将禁止生成分享视频",
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
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "礼物设置"),
              ItemBuilder.buildRadioItem(
                value: acceptGiftFlag,
                context: context,
                title: "接受礼物",
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
              ItemBuilder.buildRadioItem(
                value: showReturnGiftPreviewImg,
                bottomRadius: true,
                context: context,
                title: "支持图片模糊预览",
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
