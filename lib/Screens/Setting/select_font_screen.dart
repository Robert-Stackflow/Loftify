import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';
import 'package:loftify/Utils/file_util.dart';
import 'package:loftify/Utils/hive_util.dart';
import 'package:loftify/Utils/itoast.dart';
import 'package:loftify/Widgets/Dialog/dialog_builder.dart';

import '../../Resources/fonts.dart';
import '../../Utils/responsive_util.dart';
import '../../Widgets/General/EasyRefresh/easy_refresh.dart';
import '../../Widgets/Item/item_builder.dart';
import '../../generated/l10n.dart';

class SelectFontScreen extends StatefulWidget {
  const SelectFontScreen({super.key});

  static const String routeName = "/setting/font";

  @override
  State<SelectFontScreen> createState() => _SelectFontScreenState();
}

class _SelectFontScreenState extends State<SelectFontScreen>
    with TickerProviderStateMixin {
  CustomFont _currentFont = CustomFont.getCurrentFont();
  List<CustomFont> customFonts = HiveUtil.getCustomFonts();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Scaffold(
        appBar: ItemBuilder.buildResponsiveAppBar(
          showBack: true,
          transparent: true,
          title: S.current.chooseFontFamily,
          context: context,
          background: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: EasyRefresh(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              if (ResponsiveUtil.isLandscape()) const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.defaultFontFamily),
              ItemBuilder.buildContainerItem(
                context: context,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: _buildDefaultFontList(),
                  ),
                ),
                bottomRadius: true,
              ),
              const SizedBox(height: 10),
              ItemBuilder.buildCaptionItem(
                  context: context, title: S.current.customFontFamily),
              ItemBuilder.buildContainerItem(
                context: context,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: _buildCustomFontList(),
                  ),
                ),
                bottomRadius: true,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultFontList() {
    var list = List<Widget>.generate(
      CustomFont.defaultFonts.length,
      (index) => ItemBuilder.buildFontItem(
        currentFont: _currentFont,
        font: CustomFont.defaultFonts[index],
        context: context,
        onChanged: (_) {
          _currentFont = CustomFont.defaultFonts[index];
          appProvider.currentFont = _currentFont;
          setState(() {});
          CustomFont.loadFont(context, _currentFont, autoRestartApp: false);
        },
      ),
    );
    return list;
  }

  List<Widget> _buildCustomFontList() {
    var list = List<Widget>.generate(
      customFonts.length,
      (index) => ItemBuilder.buildFontItem(
        currentFont: _currentFont,
        showDelete: true,
        font: customFonts[index],
        context: context,
        onChanged: (_) {
          _currentFont = customFonts[index];
          appProvider.currentFont = _currentFont;
          setState(() {});
          CustomFont.loadFont(context, customFonts[index],
              autoRestartApp: false);
        },
        onDelete: (_) {
          DialogBuilder.showConfirmDialog(
            context,
            title: S.current.deleteFont(customFonts[index].intlFontName),
            message:
                S.current.deleteFontMessage(customFonts[index].intlFontName),
            onTapConfirm: () async {
              if (customFonts[index] == _currentFont) {
                _currentFont = CustomFont.Default;
                appProvider.currentFont = _currentFont;
                setState(() {});
                CustomFont.loadFont(context, _currentFont,
                    autoRestartApp: false);
              }
              await CustomFont.deleteFont(customFonts[index]);
              customFonts.removeAt(index);
              HiveUtil.setCustomFonts(customFonts);
              setState(() {});
            },
          );
        },
      ),
    );
    list.add(
      ItemBuilder.buildEmptyFontItem(
        context: context,
        onTap: () async {
          FilePickerResult? result = await FileUtil.pickFiles(
            dialogTitle: S.current.loadFontFamily,
            allowedExtensions: ['ttf', 'otf'],
            lockParentWindow: true,
            type: FileType.custom,
          );
          if (result != null) {
            CustomFont? customFont =
                await CustomFont.copyFont(filePath: result.files.single.path!);
            if (customFont != null) {
              customFonts.add(customFont);
              HiveUtil.setCustomFonts(customFonts);
              _currentFont = customFont;
              appProvider.currentFont = _currentFont;
              CustomFont.loadFont(context, _currentFont, autoRestartApp: false);
              setState(() {});
            } else {
              IToast.showTop(S.current.fontFamlyLoadFailed);
            }
          }
        },
      ),
    );
    return list;
  }
}
