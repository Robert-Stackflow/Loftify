import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/filename_setting_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/route_util.dart';

import '../../Utils/cloud_control_provider.dart';
import '../../Utils/constant.dart';
import '../../Utils/hive_util.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/BottomSheet/bottom_sheet_builder.dart';
import '../../Widgets/BottomSheet/list_bottom_sheet.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class ImageSettingScreen extends StatefulWidget {
  const ImageSettingScreen({super.key});

  static const String routeName = "/setting/image";

  @override
  State<ImageSettingScreen> createState() => _ImageSettingScreenState();
}

class _ImageSettingScreenState extends State<ImageSettingScreen>
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
  bool followMainColor = HiveUtil.getBool(HiveUtil.followMainColorKey);
  String? savePath = HiveUtil.getString(HiveUtil.savePathKey);
  String _filenameFormat = HiveUtil.getString(HiveUtil.filenameFormatKey,
          defaultValue: defaultFilenameFormat) ??
      defaultFilenameFormat;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  showImageQualitySelect({
    Function(ImageQuality)? onSelected,
    dynamic selected,
    required String title,
  }) {
    BottomSheetBuilder.showListBottomSheet(
      context,
      (context) => TileList.fromOptions(
        EnumsLabelGetter.getImageQualityLabels(),
        (item2) {
          onSelected?.call(item2);
          Navigator.pop(context);
        },
        selected: selected,
        context: context,
        title: title,
        onCloseTap: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showImageQualitySettings =
        controlProvider.globalControl.showImageQualitySettings;
    bool showBigImageSettings =
        controlProvider.globalControl.showBigImageSettings;
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildDesktopAppBar(
          showBack: true,
          title: S.current.imageSetting,
          transparent: true,
          context: context,
          background: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              if (showImageQualitySettings) ..._imageQualitySettings(),
              if (showImageQualitySettings) const SizedBox(height: 10),
              if (showBigImageSettings) ..._bigImageSettings(),
              if (showImageQualitySettings || showBigImageSettings)
                const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.downloadImageSetting),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.downloadImagePath,
                description: savePath ?? "",
                tip: S.current.edit,
                onTap: () async {
                  String? selectedDirectory =
                      await FilePicker.platform.getDirectoryPath(
                    dialogTitle: S.current.chooseDownloadImagePath,
                    lockParentWindow: true,
                  );
                  if (selectedDirectory != null) {
                    setState(() {
                      savePath = selectedDirectory;
                      HiveUtil.put(HiveUtil.savePathKey, selectedDirectory);
                    });
                  }
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: S.current.filenameFormat,
                description: _filenameFormat,
                tip: S.current.edit,
                bottomRadius: true,
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  _imageQualitySettings() {
    return [
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.imageQuality),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.waterfallFlowImageQuality,
        tip: EnumsLabelGetter.getImageQualityLabel(waterfallFlowImageQuality),
        onTap: () {
          showImageQualitySelect(
            onSelected: (quality) {
              setState(() {
                waterfallFlowImageQuality = quality;
                HiveUtil.put(
                    HiveUtil.waterfallFlowImageQualityKey, quality.index);
              });
            },
            selected: waterfallFlowImageQuality,
            title: S.current.chooseWaterfallFlowImageQuality,
          );
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.postDetailImageQuality,
        tip: EnumsLabelGetter.getImageQualityLabel(postDetailImageQuality),
        onTap: () {
          showImageQualitySelect(
            onSelected: (quality) {
              setState(() {
                postDetailImageQuality = quality;
                HiveUtil.put(HiveUtil.postDetailImageQualityKey, quality.index);
              });
            },
            selected: postDetailImageQuality,
            title: S.current.choosePostDetailImageQuality,
          );
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.bigImageQuality,
        tip: EnumsLabelGetter.getImageQualityLabel(imageDetailImageQuality),
        bottomRadius: true,
        onTap: () {
          showImageQualitySelect(
            onSelected: (quality) {
              setState(() {
                imageDetailImageQuality = quality;
                HiveUtil.put(
                    HiveUtil.imageDetailImageQualityKey, quality.index);
              });
            },
            selected: imageDetailImageQuality,
            title: S.current.chooseBigImageQuality,
          );
        },
      ),
    ];
  }

  _bigImageSettings() {
    return [
      ItemBuilder.buildCaptionItem(
          context: context, title: S.current.bigImageSetting),
      ItemBuilder.buildRadioItem(
        value: followMainColor,
        context: context,
        title: S.current.backgroundColorFollowMainColor,
        onTap: () {
          setState(() {
            followMainColor = !followMainColor;
            HiveUtil.put(
              HiveUtil.followMainColorKey,
              followMainColor,
            );
          });
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.tapLinkButton,
        tip: EnumsLabelGetter.getImageQualityLabel(tapLinkButtonImageQuality),
        description: S.current.tapLinkButtonDescription,
        onTap: () {
          showImageQualitySelect(
            onSelected: (quality) {
              setState(() {
                tapLinkButtonImageQuality = quality;
                HiveUtil.put(
                    HiveUtil.tapLinkButtonImageQualityKey, quality.index);
              });
            },
            selected: tapLinkButtonImageQuality,
            title: S.current.chooseTapLinkButton,
          );
        },
      ),
      ItemBuilder.buildEntryItem(
        context: context,
        title: S.current.longPressLinkButton,
        tip: EnumsLabelGetter.getImageQualityLabel(
            longPressLinkButtonImageQuality),
        description: S.current.longPressLinkButtonDescription,
        bottomRadius: true,
        onTap: () {
          showImageQualitySelect(
            onSelected: (quality) {
              setState(() {
                longPressLinkButtonImageQuality = quality;
                HiveUtil.put(
                    HiveUtil.longPressLinkButtonImageQualityKey, quality.index);
              });
            },
            selected: longPressLinkButtonImageQuality,
            title: S.current.chooseLongPressLinkButton,
          );
        },
      ),
    ];
  }
}
