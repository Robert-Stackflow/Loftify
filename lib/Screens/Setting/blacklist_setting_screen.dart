import 'package:flutter/material.dart';
import 'package:loftify/Api/user_api.dart';
import 'package:loftify/Models/user_response.dart';
import 'package:loftify/Screens/Info/user_detail_screen.dart';
import 'package:loftify/Utils/route_util.dart';

import '../../Api/setting_api.dart';
import '../../Resources/theme.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/Dialog/custom_dialog.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class BlacklistSettingScreen extends StatefulWidget {
  const BlacklistSettingScreen({super.key});

  static const String routeName = "/setting/blacklist";

  @override
  State<BlacklistSettingScreen> createState() => _BlacklistSettingScreenState();
}

class _BlacklistSettingScreenState extends State<BlacklistSettingScreen>
    with TickerProviderStateMixin {
  bool loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  List<BlacklistItem> blacklist = [];
  bool _noMore = false;

  _fetchBlacklist({bool refresh = false}) async {
    if (loading) return;
    if (refresh) _noMore = false;
    loading = true;
    return await SettingApi.getBlacklist(offset: refresh ? 0 : blacklist.length)
        .then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          var tmp = (value['response']['blogs'] as List)
              .map((e) => BlacklistItem.fromJson(e))
              .toList();
          if (refresh) blacklist.clear();
          blacklist.addAll(tmp);
          if (tmp.isEmpty && !refresh) {
            _noMore = true;
            return IndicatorResult.noMore;
          }
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load blacklist", e, t);
        IToast.showTop("黑名单加载失败");
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
      backgroundColor: MyTheme.getBackground(context),
      appBar: ItemBuilder.buildDesktopAppBar(
        showBack: true,
        showBorder: true,
        title: S.current.blacklistSetting,
        context: context,
      ),
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          return await _fetchBlacklist(refresh: true);
        },
        onLoad: () async {
          return await _fetchBlacklist();
        },
        triggerAxis: Axis.vertical,
        child: ItemBuilder.buildLoadMoreNotification(
          child: ListView.builder(
            itemCount: blacklist.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) =>
                _buildBlacklistRow(blacklist[index]),
          ),
          noMore: _noMore,
          onLoad: _fetchBlacklist,
        ),
      ),
    );
  }

  _buildBlacklistRow(BlacklistItem blacklistItem) {
    return GestureDetector(
      onTap: () {
        RouteUtil.pushPanelCupertinoRoute(
          context,
          UserDetailScreen(
              blogId: blacklistItem.blogInfo.blogId,
              blogName: blacklistItem.blogInfo.blogName),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            ItemBuilder.buildAvatar(
              context: context,
              imageUrl: blacklistItem.blogInfo.bigAvaImg,
              showLoading: false,
              showBorder: true,
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(blacklistItem.blogInfo.blogNickName),
            ),
            ItemBuilder.buildFramedDoubleButton(
              context: context,
              isFollowed: false,
              positiveText: "解除黑名单",
              negtiveText: "解除黑名单",
              onTap: () {
                DialogBuilder.showConfirmDialog(
                  context,
                  title: "解除黑名单",
                  message: "确认解除「${blacklistItem.blogInfo.blogNickName}」的黑名单？",
                  confirmButtonText: "解除",
                  cancelButtonText: "取消",
                  onTapConfirm: () {
                    UserApi.blockOrUnBlock(
                      blogId: blacklistItem.blogInfo.blogId,
                      isBlock: false,
                    ).then((value) {
                      if (value['meta']['status'] != 200) {
                        IToast.showTop(
                            value['meta']['desc'] ?? value['meta']['msg']);
                      } else {
                        blacklist.remove(blacklistItem);
                        setState(() {});
                      }
                    });
                  },
                  onTapCancel: () {},
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
