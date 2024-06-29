import 'package:flutter/material.dart';
import 'package:loftify/Models/recommend_response.dart';

import '../../Api/setting_api.dart';
import '../../Api/user_api.dart';
import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Utils/route_util.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';
import '../Info/user_detail_screen.dart';

class UserDynamicShieldSettingScreen extends StatefulWidget {
  const UserDynamicShieldSettingScreen({super.key});

  static const String routeName = "/setting/userDynamicShield";

  @override
  State<UserDynamicShieldSettingScreen> createState() =>
      _UserDynamicShieldSettingScreenState();
}

class _UserDynamicShieldSettingScreenState
    extends State<UserDynamicShieldSettingScreen>
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
          IToast.showTop(context, text: value['desc'] ?? value['msg']);
          return IndicatorResult.fail;
        } else {
          shieldList.clear();
          var tmp = (value['data']['blogInfos'] as List)
              .map((e) => SimpleBlogInfo.fromJson(e))
              .toList();
          shieldList.addAll(tmp);
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "不看TA的动态列表加载失败");
        return IndicatorResult.fail;
      } finally {
        loading = false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackground(context),
      appBar: ItemBuilder.buildAppBar(
        leading: Icons.arrow_back_rounded,
        backgroundColor: AppTheme.getBackground(context),
        onLeadingTap: () {
          Navigator.pop(context);
        },
        title: Text(S.current.userDynamicShieldSetting,
            style: Theme.of(context).textTheme.titleLarge),
        center: true,
        context: context,
        actions: [
          ItemBuilder.buildBlankIconButton(context),
        ]
      ),
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          return await _fetchShieldList();
        },
        triggerAxis: Axis.vertical,
        child: ListView.builder(
          itemCount: shieldList.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) =>
              _buildShieldlistRow(shieldList[index]),
        ),
      ),
    );
  }

  _buildShieldlistRow(SimpleBlogInfo blogInfo) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushCupertinoRoute(
          context,
          UserDetailScreen(
              blogId: blogInfo.blogId, blogName: blogInfo.blogName),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              imageUrl: blogInfo.bigAvaImg,
              showLoading: false,
              showBorder: true,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(blogInfo.blogNickName),
            ),
            ItemBuilder.buildFramedButton(
              context: context,
              isFollowed: false,
              positiveText: "恢复查看",
              negtiveText: "恢复查看",
              onTap: () {
                CustomConfirmDialog.showAnimatedFromBottom(
                  context,
                  message: "确认恢复查看「${blogInfo.blogNickName}」的动态？",
                  confirmButtonText: "确认",
                  cancelButtonText: "取消",
                  onTapConfirm: () {
                    Navigator.pop(context);
                    UserApi.shieldBlogOrUnShield(
                      blogId: blogInfo.blogId,
                      isShield: false,
                    ).then((value) {
                      if (value['code'] != 0) {
                        IToast.showTop(context, text: value['msg']);
                      } else {
                        shieldList.remove(blogInfo);
                        setState(() {});
                      }
                    });
                  },
                  onTapCancel: () {
                    Navigator.pop(context);
                  },
                  customDialogType: CustomDialogType.normal,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
