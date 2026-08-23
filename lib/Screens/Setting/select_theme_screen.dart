import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';
import 'package:loftify/Utils/app_provider.dart';

import '../../Widgets/Item/item_builder.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'base_setting_screen.dart';

class SelectThemeScreen extends BaseSettingScreen {
  const SelectThemeScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/theme";

  @override
  State<SelectThemeScreen> createState() => _SelectThemeScreenState();
}

class _SelectThemeScreenState extends BaseDynamicState<SelectThemeScreen>
    with TickerProviderStateMixin {
  static const List<Color> _presetAccentColors = [
    Color(0xFF14C2BB),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFF3F51B5),
  ];

  int _selectedLightIndex = ChewieHiveUtil.getLightThemeIndex();
  int _selectedDarkIndex = ChewieHiveUtil.getDarkThemeIndex();
  int _lightPrimaryColorIndex = ChewieHiveUtil.getLightThemePrimaryColorIndex();
  int _darkPrimaryColorIndex = ChewieHiveUtil.getDarkThemePrimaryColorIndex();

  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.selectTheme,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.lightTheme,
          children: [
            _buildThemeScroller(_buildLightThemeList()),
            _buildAccentColorPalette(isDark: false),
          ],
        ),
        CaptionItem(
          context: context,
          title: appLocalizations.darkTheme,
          children: [
            _buildThemeScroller(_buildDarkThemeList()),
            _buildAccentColorPalette(isDark: true),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeScroller(List<Widget> children) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(child: Row(children: children)),
        ),
      ),
    );
  }

  List<Widget> _buildLightThemeList() {
    final themes = [
      ...ChewieThemeColorData.defaultLightThemes,
      ...appProvider.customLightThemes,
    ];
    return List<Widget>.generate(
      themes.length,
      (index) => ItemBuilder.buildThemeItem(
        index: index,
        groupIndex: _selectedLightIndex,
        themeColorData: themes[index],
        context: context,
        onChanged: (index) {
          setState(() {
            _selectedLightIndex = index ?? 0;
            appProvider.setLightTheme(_selectedLightIndex);
          });
        },
      ),
    );
  }

  List<Widget> _buildDarkThemeList() {
    final themes = [
      ...ChewieThemeColorData.defaultDarkThemes,
      ...appProvider.customDarkThemes,
    ];
    return List<Widget>.generate(
      themes.length,
      (index) => ItemBuilder.buildThemeItem(
        index: index,
        groupIndex: _selectedDarkIndex,
        themeColorData: themes[index],
        context: context,
        onChanged: (index) {
          setState(() {
            _selectedDarkIndex = index ?? 0;
            appProvider.setDarkTheme(_selectedDarkIndex);
          });
        },
      ),
    );
  }

  Widget _buildAccentColorPalette({required bool isDark}) {
    final selectedIndex =
        isDark ? _darkPrimaryColorIndex : _lightPrimaryColorIndex;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              appLocalizations.primaryColor,
              style: ChewieTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildAccentCircle(
                  color: null,
                  isSelected: selectedIndex == 0,
                  onTap: () => _setAccentColor(isDark, null, 0),
                ),
                for (int index = 0; index < _presetAccentColors.length; index++)
                  _buildAccentCircle(
                    color: _presetAccentColors[index],
                    isSelected: selectedIndex == index + 1,
                    onTap: () => _setAccentColor(
                      isDark,
                      _presetAccentColors[index],
                      index + 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setAccentColor(bool isDark, Color? color, int paletteIndex) {
    setState(() {
      if (isDark) {
        _darkPrimaryColorIndex = paletteIndex;
        appProvider.setDarkPrimaryColorOverride(color, paletteIndex);
      } else {
        _lightPrimaryColorIndex = paletteIndex;
        appProvider.setLightPrimaryColorOverride(color, paletteIndex);
      }
    });
  }

  Widget _buildAccentCircle({
    required Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkAnimation(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? ChewieTheme.primaryColor
                : ChewieTheme.dividerColor,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: color == null
            ? Icon(
                LoftifyIcons.reset,
                size: 18,
                color: ChewieTheme.iconColor,
              )
            : isSelected
                ? const ChewieIcon(
                    LoftifyIcons.check,
                    size: 18,
                    color: Colors.white,
                  )
                : null,
      ),
    );
  }
}
