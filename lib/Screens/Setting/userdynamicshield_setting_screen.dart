import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Models/recommend_response.dart';

import '../../Api/setting_api.dart';
import '../../Api/user_api.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/setting_management_item.dart';
import '../../l10n/l10n.dart';
import '../Info/user_detail_screen.dart';
import 'base_setting_screen.dart';

class UserDynamicShieldSettingScreen extends BaseSettingScreen {
  const UserDynamicShieldSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/userDynamicShield";

  @override
  State<UserDynamicShieldSettingScreen> createState() =>
      _UserDynamicShieldSettingScreenState();
}

class _UserDynamicShieldSettingScreenState
    extends BaseDynamicState<UserDynamicShieldSettingScreen>
    with TickerProviderStateMixin {
  bool loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  List<SimpleBlogInfo> shieldList = [];

  _fetchShieldList() async {
    if (loading) return;
    loading = true;
    return await SettingApi.getShieldBloglist().then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['code'] != 0) {
          IToast.showTop(value['desc'] ?? value['msg']);
          return IndicatorResult.fail;
        } else {
          shieldList.clear();
          var tmp = (value['data']['blogInfos'] as List)
              .map((e) => SimpleBlogInfo.fromJson(e))
              .toList();
          shieldList.addAll(tmp);
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load user dynamic shield list", e, t);
        IToast.showTop(appLocalizations.loadFailed);
        return IndicatorResult.fail;
      } finally {
        loading = false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.userDynamicShieldSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      overrideBody: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          return await _fetchShieldList();
        },
        triggerAxis: Axis.vertical,
        child: ListView(
          padding: widget.padding,
          children: [
            CaptionItem(
              title:
                  '${appLocalizations.userDynamicShieldSetting} (${shieldList.length})',
              children: shieldList.isEmpty
                  ? [
                      SizedBox(
                        height: 140,
                        child: EmptyPlaceholder(
                          text: appLocalizations.noContent,
                          physics: const NeverScrollableScrollPhysics(),
                          topPadding: 20,
                        ),
                      ),
                    ]
                  : shieldList.map(_buildShieldlistRow).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShieldlistRow(SimpleBlogInfo blogInfo) {
    return SettingManagementItem(
      title: blogInfo.blogNickName,
      description: blogInfo.blogName,
      leading: ItemBuilder.buildAvatar(
        context: context,
        imageUrl: blogInfo.bigAvaImg,
        showLoading: false,
        showBorder: true,
        size: 40,
      ),
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
              blogId: blogInfo.blogId, blogName: blogInfo.blogName),
        );
      },
      actionLabel: appLocalizations.resumeView,
      onAction: () {
        DialogBuilder.showConfirmDialog(
          context,
          title: appLocalizations.resumeViewDynamic,
          message:
              appLocalizations.resumeViewDynamicMessage(blogInfo.blogNickName),
          onTapConfirm: () {
            UserApi.shieldBlogOrUnShield(
              blogId: blogInfo.blogId,
              isShield: false,
            ).then((value) {
              if (value['code'] != 0) {
                IToast.showTop(value['msg']);
              } else {
                shieldList.remove(blogInfo);
                setState(() {});
              }
            });
          },
        );
      },
    );
  }
}
