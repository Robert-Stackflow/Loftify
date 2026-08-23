import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';

import '../../Widgets/Item/item_builder.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class SelectFontScreen extends BaseSettingScreen {
  const SelectFontScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/font";

  @override
  State<SelectFontScreen> createState() => _SelectFontScreenState();
}

class _SelectFontScreenState extends BaseDynamicState<SelectFontScreen>
    with TickerProviderStateMixin {
  CustomFont _currentFont = CustomFont.getCurrentFont();
  List<CustomFont> customFonts = ChewieHiveUtil.getCustomFonts();

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.chooseFontFamily,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.defaultFontFamily,
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              child: Wrap(
                runSpacing: 10,
                spacing: 10,
                children: _buildDefaultFontList(),
              ),
            ),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.customFontFamily,
          children: [
            Container(
              margin: const EdgeInsets.all(10),
              child: Wrap(
                runSpacing: 10,
                spacing: 10,
                children: _buildCustomFontList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildDefaultFontList() {
    var list = List<Widget>.generate(
      CustomFont.defaultFonts.length,
      (index) => ItemBuilder.buildFontItem(
        currentFont: _currentFont,
        font: CustomFont.defaultFonts[index],
        context: context,
        onChanged: (_) => _applyFont(CustomFont.defaultFonts[index]),
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
        onChanged: (_) => _applyFont(customFonts[index]),
        onDelete: (_) {
          DialogBuilder.showConfirmDialog(
            context,
            title: appLocalizations.deleteFont(customFonts[index].intlFontName),
            message: appLocalizations
                .deleteFontMessage(customFonts[index].intlFontName),
            onTapConfirm: () async {
              if (customFonts[index] == _currentFont) {
                final applied = await _applyFont(CustomFont.Default);
                if (!applied) return;
              }
              await CustomFont.deleteFont(customFonts[index]);
              customFonts.removeAt(index);
              ChewieHiveUtil.setCustomFonts(customFonts);
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
            dialogTitle: appLocalizations.loadFontFamily,
            allowedExtensions: ['ttf', 'otf'],
            lockParentWindow: true,
            type: FileType.custom,
          );
          if (result != null) {
            CustomFont? customFont =
                await CustomFont.copyFont(filePath: result.files.single.path!);
            if (customFont != null) {
              customFonts.add(customFont);
              ChewieHiveUtil.setCustomFonts(customFonts);
              await _applyFont(customFont);
            } else {
              IToast.showTop(appLocalizations.fontFamlyLoadFailed);
            }
          }
        },
      ),
    );
    return list;
  }

  Future<bool> _applyFont(CustomFont font) async {
    final applied = await CustomFont.loadFont(
      context,
      font,
      autoRestartApp: false,
    );
    if (!mounted || !applied) return false;
    setState(() => _currentFont = font);
    appProvider.currentFont = font;
    return true;
  }
}
