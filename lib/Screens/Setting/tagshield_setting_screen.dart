import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Api/setting_api.dart';

import '../../Widgets/Item/setting_management_item.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class TagShieldSettingScreen extends BaseSettingScreen {
  const TagShieldSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/tagShield";

  @override
  State<TagShieldSettingScreen> createState() => _TagShieldSettingScreenState();
}

class _TagShieldSettingScreenState
    extends BaseDynamicState<TagShieldSettingScreen>
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
      title: appLocalizations.tagShieldSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      actions: [
        CircleIconButton(
          context: context,
          icon:
              Icon(Icons.add_rounded, color: Theme.of(context).iconTheme.color),
          onTap: () {
            BottomSheetBuilder.showBottomSheet(
              context,
              (sheetContext) => InputBottomSheet(
                buttonText: appLocalizations.confirm,
                title: appLocalizations.addShieldTag,
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
      overrideBody: EasyRefresh(
        controller: _refreshController,
        refreshOnStart: true,
        onRefresh: () async {
          return await _fetchTags();
        },
        triggerAxis: Axis.vertical,
        child: ListView(
          padding: widget.padding,
          children: [
            CaptionItem(
              title: '${appLocalizations.tagShieldSetting} (${tags.length})',
              children: tags.isEmpty
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
                  : tags.map(_buildTagRow).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(String tag) {
    return SettingManagementItem(
      title: tag,
      leadingIcon: Icons.tag_rounded,
      actionLabel: appLocalizations.unblockShieldTag,
      onAction: () {
        DialogBuilder.showConfirmDialog(
          context,
          title: appLocalizations.unblockShieldTag,
          message: appLocalizations.unblockShieldTagMessage(tag),
          confirmButtonText: appLocalizations.unlock,
          onTapConfirm: () {
            SettingApi.shieldOrUnshieldTag(tag: tag, isShield: false)
                .then((value) {
              IToast.showTop(value['meta']['desc'] ?? value['meta']['msg']);
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
    );
  }
}
