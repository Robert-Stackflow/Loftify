import 'package:flutter/material.dart';
import 'package:loftify/Api/setting_api.dart';
import 'package:loftify/Widgets/BottomSheet/input_bottom_sheet.dart';
import 'package:loftify/Widgets/Dialog/custom_dialog.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../Resources/theme.dart';
import '../../Utils/itoast.dart';
import '../../Widgets/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
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
          IToast.showTop(context,
              text: value['meta']['desc'] ?? value['meta']['msg']);
          return IndicatorResult.fail;
        } else {
          tags = (value['response']['list'] as List)
              .map((e) => e.toString())
              .toList();
          return IndicatorResult.success;
        }
      } catch (_) {
        IToast.showTop(context, text: "屏蔽标签加载失败");
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
        title: Text("${S.current.tagShieldSetting}(${tags.length})",
            style: Theme.of(context).textTheme.titleLarge),
        center: true,
        context: context,
        actions: [
          ItemBuilder.buildIconButton(
            context: context,
            icon: Icon(Icons.add_rounded,
                color: Theme.of(context).iconTheme.color),
            onTap: () {
              showMaterialModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                builder: (sheetContext) => InputBottomSheet(
                  buttonText: "确认",
                  title: "添加屏蔽标签",
                  text: "",
                  onConfirm: (text) {
                    SettingApi.shieldOrUnshieldTag(tag: text, isShield: true)
                        .then((value) {
                      IToast.showTop(context,
                          text: value['meta']['desc'] ?? value['meta']['msg']);
                      if (value['meta']['status'] == 200) {
                        tags.insert(0, text);
                        setState(() {});
                      }
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 5),
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
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(tag),
          ),
          ItemBuilder.buildFramedButton(
            context: context,
            isFollowed: false,
            positiveText: "解除屏蔽",
            negtiveText: "解除屏蔽",
            onTap: () {
              CustomConfirmDialog.showAnimatedFromBottom(
                context,
                message: "确认解除屏蔽「$tag」？",
                confirmButtonText: "解除",
                cancelButtonText: "取消",
                onTapConfirm: () {
                  Navigator.pop(context);
                  SettingApi.shieldOrUnshieldTag(tag: tag, isShield: false)
                      .then((value) {
                    IToast.showTop(context,
                        text: value['meta']['desc'] ?? value['meta']['msg']);
                    if (value['meta']['status'] == 200) {
                      tags.remove(tag);
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
    );
  }
}
