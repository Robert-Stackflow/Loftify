import 'package:flutter/material.dart';
import 'package:loftify/Api/setting_api.dart';
import 'package:loftify/Widgets/BottomSheet/input_bottom_sheet.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';

import '../../Resources/theme.dart';
import '../../Utils/ilogger.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/Dialog/dialog_builder.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/Item/loftify_item_builder.dart';
import '../../generated/l10n.dart';

class TagShieldSettingScreen extends StatefulWidget {
  const TagShieldSettingScreen({super.key});

  static const String routeName = "/setting/tagShield";

  @override
  State<TagShieldSettingScreen> createState() => _TagShieldSettingScreenState();
}

class _TagShieldSettingScreenState extends State<TagShieldSettingScreen>
    with TickerProviderStateMixin {
  bool loading = false;
  final EasyRefreshController _refreshController = EasyRefreshController();
  List<String> tags = [];

  _fetchTags() async {
    if (loading) return;
    loading = true;
    return await SettingApi.getShieldTagList().then((value) {
      try {
        if (value == null) return IndicatorResult.fail;
        if (value['meta']['status'] != 200) {
          IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          tags = (value['response']['list'] as List)
              .map((e) => e.toString())
              .toList();
          return IndicatorResult.success;
        }
      } catch (e, t) {
        ILogger.error("Failed to load tag shield list", e, t);
        IToast.showTop(S.current.loadFailed);
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
      appBar: ItemBuilder.buildResponsiveAppBar(
        showBack: true,
        showBorder: true,
        title: "${S.current.tagShieldSetting}(${tags.length})",
        context: context,
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.add_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              BottomSheetBuilder.showBottomSheet(
                context,
                (sheetContext) => InputBottomSheet(
                  buttonText: S.current.confirm,
                  title: S.current.addShieldTag,
                  text: "",
                  onConfirm: (text) {
                    SettingApi.shieldOrUnshieldTag(tag: text, isShield: true)
                        .then((value) {
                      IToast.showTop(
                          value['meta']['desc'] ?? value['meta']['msg']);
                      if (value['meta']['status'] == 200) {
                        tags.insert(0, text);
                        setState(() {});
                      }
                    });
                  },
                ),
                preferMinWidth: 400,
                responsive: true,
              );
            },
          ),
        ],
      ),
      body: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () {
          _fetchTags();
        },
        triggerAxis: Axis.vertical,
        child: ListView.builder(
          itemCount: tags.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) => _buildTagRow(tags[index]),
        ),
      ),
    );
  }

  _buildTagRow(String tag) {
    return Container(
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
          Expanded(
            child: Text(tag),
          ),
          LoftifyItemBuilder.buildFramedDoubleButton(
            context: context,
            isFollowed: false,
            positiveText: S.current.unblockShieldTag,
            negtiveText: S.current.unblockShieldTag,
            onTap: () {
              DialogBuilder.showConfirmDialog(
                context,
                title: S.current.unblockShieldTag,
                message: S.current.unblockShieldTagMessage(tag),
                confirmButtonText: S.current.unlock,
                onTapConfirm: () {
                  SettingApi.shieldOrUnshieldTag(tag: tag, isShield: false)
                      .then((value) {
                    IToast.showTop(
                        value['meta']['desc'] ?? value['meta']['msg']);
                    if (value['meta']['status'] == 200) {
                      tags.remove(tag);
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
    );
  }
}
