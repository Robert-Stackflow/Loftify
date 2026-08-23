import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Download/download_management_screen.dart';
import 'package:loftify/Screens/Setting/filename_setting_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../Utils/cloud_control_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class ImageSettingScreen extends BaseSettingScreen {
  const ImageSettingScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/image";

  @override
  State<ImageSettingScreen> createState() => _ImageSettingScreenState();
}

class _ImageSettingScreenState extends BaseDynamicState<ImageSettingScreen>
    with TickerProviderStateMixin {
  ImageQuality waterfallFlowImageQuality =
      HiveUtil.getImageQuality(HiveUtil.waterfallFlowImageQualityKey);
  ImageQuality postDetailImageQuality =
      HiveUtil.getImageQuality(HiveUtil.postDetailImageQualityKey);
  ImageQuality imageDetailImageQuality =
      HiveUtil.getImageQuality(HiveUtil.imageDetailImageQualityKey);
  ImageQuality tapLinkButtonImageQuality =
      HiveUtil.getImageQuality(HiveUtil.tapLinkButtonImageQualityKey);
  ImageQuality longPressLinkButtonImageQuality =
      HiveUtil.getImageQuality(HiveUtil.longPressLinkButtonImageQualityKey);
  bool followMainColor = ChewieHiveUtil.getBool(HiveUtil.followMainColorKey);
  String? savePath = ChewieHiveUtil.getString(HiveUtil.savePathKey);
  String _filenameFormat = ChewieHiveUtil.getString(HiveUtil.filenameFormatKey,
          defaultValue: defaultFilenameFormat) ??
      defaultFilenameFormat;

  @override
  Widget build(BuildContext context) {
    bool showImageQualitySettings =
        controlProvider.globalControl.showImageQualitySettings;
    bool showBigImageSettings =
        controlProvider.globalControl.showBigImageSettings;
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.imageSetting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        if (showImageQualitySettings) ..._imageQualitySettings(),
        if (showBigImageSettings) ..._bigImageSettings(),
        CaptionItem(
          context: context,
          title: appLocalizations.downloadImageSetting,
          children: [
            EntryItem(
              context: context,
              title: appLocalizations.downloadManagement,
              showLeading: true,
              leading: LucideIcons.download,
              onTap: () {
                RouteUtil.pushPanelCupertinoRoute(
                  context,
                  const DownloadManagementScreen(),
                );
              },
            ),
            EntryItem(
              context: context,
              title: appLocalizations.downloadImagePath,
              description: savePath ?? "",
              tip: appLocalizations.edit,
              onTap: () async {
                String? selectedDirectory =
                    await FilePicker.platform.getDirectoryPath(
                  dialogTitle: appLocalizations.chooseDownloadImagePath,
                  lockParentWindow: true,
                );
                if (selectedDirectory != null) {
                  setState(() {
                    savePath = selectedDirectory;
                    ChewieHiveUtil.put(HiveUtil.savePathKey, selectedDirectory);
                  });
                }
              },
            ),
            EntryItem(
              context: context,
              title: appLocalizations.filenameFormat,
              description: _filenameFormat,
              tip: appLocalizations.edit,
              onTap: () {
                var page = FilenameSettingScreen(
                  onSaved: (newFormat) {
                    setState(() {
                      _filenameFormat = newFormat;
                    });
                  },
                );
                RouteUtil.pushPanelCupertinoRoute(context, page);
              },
            ),
          ],
        ),
      ],
    );
  }

  List<SelectionItemModel<ImageQuality>> get _imageQualityOptions =>
      EnumsLabelGetter.getImageQualityLabels()
          .map((option) => SelectionItemModel(option.item1, option.item2))
          .toList();

  Widget _buildImageQualitySelection({
    required String title,
    String description = "",
    required String hint,
    required ImageQuality selected,
    required ValueChanged<ImageQuality> onChanged,
  }) {
    return InlineSelectionItem<SelectionItemModel<ImageQuality>>(
      title: title,
      description: description,
      items: _imageQualityOptions,
      initItem: SelectionItemModel(
        EnumsLabelGetter.getImageQualityLabel(selected),
        selected,
      ),
      hint: hint,
      onChanged: (item) {
        if (item != null) onChanged(item.value);
      },
    );
  }

  List<Widget> _imageQualitySettings() {
    return [
      CaptionItem(
        context: context,
        title: appLocalizations.imageQuality,
        children: [
          _buildImageQualitySelection(
            title: appLocalizations.waterfallFlowImageQuality,
            hint: appLocalizations.chooseWaterfallFlowImageQuality,
            selected: waterfallFlowImageQuality,
            onChanged: (quality) {
              setState(() {
                waterfallFlowImageQuality = quality;
                ChewieHiveUtil.put(
                    HiveUtil.waterfallFlowImageQualityKey, quality.index);
              });
            },
          ),
          _buildImageQualitySelection(
            title: appLocalizations.postDetailImageQuality,
            hint: appLocalizations.choosePostDetailImageQuality,
            selected: postDetailImageQuality,
            onChanged: (quality) {
              setState(() {
                postDetailImageQuality = quality;
                ChewieHiveUtil.put(
                    HiveUtil.postDetailImageQualityKey, quality.index);
              });
            },
          ),
          _buildImageQualitySelection(
            title: appLocalizations.bigImageQuality,
            hint: appLocalizations.chooseBigImageQuality,
            selected: imageDetailImageQuality,
            onChanged: (quality) {
              setState(() {
                imageDetailImageQuality = quality;
                ChewieHiveUtil.put(
                    HiveUtil.imageDetailImageQualityKey, quality.index);
              });
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _bigImageSettings() {
    return [
      CaptionItem(
        context: context,
        title: appLocalizations.bigImageSetting,
        children: [
          CheckboxItem(
            value: followMainColor,
            context: context,
            title: appLocalizations.backgroundColorFollowMainColor,
            onTap: () {
              setState(() {
                followMainColor = !followMainColor;
                ChewieHiveUtil.put(
                  HiveUtil.followMainColorKey,
                  followMainColor,
                );
              });
            },
          ),
          _buildImageQualitySelection(
            title: appLocalizations.tapLinkButton,
            description: appLocalizations.tapLinkButtonDescription,
            hint: appLocalizations.chooseTapLinkButton,
            selected: tapLinkButtonImageQuality,
            onChanged: (quality) {
              setState(() {
                tapLinkButtonImageQuality = quality;
                ChewieHiveUtil.put(
                    HiveUtil.tapLinkButtonImageQualityKey, quality.index);
              });
            },
          ),
          _buildImageQualitySelection(
            title: appLocalizations.longPressLinkButton,
            description: appLocalizations.longPressLinkButtonDescription,
            hint: appLocalizations.chooseLongPressLinkButton,
            selected: longPressLinkButtonImageQuality,
            onChanged: (quality) {
              setState(() {
                longPressLinkButtonImageQuality = quality;
                ChewieHiveUtil.put(
                    HiveUtil.longPressLinkButtonImageQualityKey, quality.index);
              });
            },
          ),
        ],
      ),
    ];
  }
}
