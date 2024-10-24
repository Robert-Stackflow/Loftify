import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Screens/Setting/filename_setting_screen.dart';
import 'package:loftify/Utils/enums.dart';
import 'package:loftify/Utils/route_util.dart';

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
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ItemBuilder.buildDesktopAppBar(
          showBack: true,
          title: S.current.imageSetting,
          transparent: true,
          context: context,
        ),
        body: EasyRefresh(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "图片质量"),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "瀑布流图片质量",
                tip: EnumsLabelGetter.getImageQualityLabel(
                    waterfallFlowImageQuality),
                onTap: () {
                  showImageQualitySelect(
                    onSelected: (quality) {
                      setState(() {
                        waterfallFlowImageQuality = quality;
                        HiveUtil.put(HiveUtil.waterfallFlowImageQualityKey,
                            quality.index);
                      });
                    },
                    selected: waterfallFlowImageQuality,
                    title: "选择瀑布流图片质量",
                  );
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "详情页图片质量",
                tip: EnumsLabelGetter.getImageQualityLabel(
                    postDetailImageQuality),
                onTap: () {
                  showImageQualitySelect(
                    onSelected: (quality) {
                      setState(() {
                        postDetailImageQuality = quality;
                        HiveUtil.put(
                            HiveUtil.postDetailImageQualityKey, quality.index);
                      });
                    },
                    selected: postDetailImageQuality,
                    title: "选择详情页图片质量",
                  );
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "查看大图时图片质量",
                tip: EnumsLabelGetter.getImageQualityLabel(
                    imageDetailImageQuality),
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
                    title: "选择查看大图时图片质量",
                  );
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "大图设置"),
              ItemBuilder.buildRadioItem(
                value: followMainColor,
                context: context,
                title: "背景跟随图片主色调",
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
                title: "点按链接按钮",
                tip: EnumsLabelGetter.getImageQualityLabel(
                    tapLinkButtonImageQuality),
                description: "点按链接按钮时复制的图片链接质量",
                onTap: () {
                  showImageQualitySelect(
                    onSelected: (quality) {
                      setState(() {
                        tapLinkButtonImageQuality = quality;
                        HiveUtil.put(HiveUtil.tapLinkButtonImageQualityKey,
                            quality.index);
                      });
                    },
                    selected: tapLinkButtonImageQuality,
                    title: "选择点按链接按钮时复制的图片链接质量",
                  );
                },
              ),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "长按链接按钮",
                tip: EnumsLabelGetter.getImageQualityLabel(
                    longPressLinkButtonImageQuality),
                description: "长按链接按钮时复制的图片链接质量",
                bottomRadius: true,
                onTap: () {
                  showImageQualitySelect(
                    onSelected: (quality) {
                      setState(() {
                        longPressLinkButtonImageQuality = quality;
                        HiveUtil.put(
                            HiveUtil.longPressLinkButtonImageQualityKey,
                            quality.index);
                      });
                    },
                    selected: longPressLinkButtonImageQuality,
                    title: "选择长按链接按钮时复制的图片链接质量",
                  );
                },
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(context: context, title: "保存设置"),
              ItemBuilder.buildEntryItem(
                context: context,
                title: "图片/视频保存路径",
                description: savePath ?? "",
                tip: "修改",
                onTap: () async {
                  String? selectedDirectory =
                      await FilePicker.platform.getDirectoryPath(
                    dialogTitle: "选择图片/视频保存路径",
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
                title: "文件命名格式",
                description: _filenameFormat,
                tip: "修改",
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
}
