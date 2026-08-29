/*
 * Copyright (c) 2024 Robert-Stackflow.
 *
 * This program is free software: you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:awesome_chewie/awesome_chewie.dart';
import 'package:flutter/material.dart';

import '../../Utils/app_provider.dart';
import '../../Widgets/loftify_icons.dart';
import '../../l10n/l10n.dart';
import 'apperance_setting_screen.dart';
import 'experiment_setting_screen.dart';
import 'general_setting_screen.dart';
import 'image_setting_screen.dart';
import 'lofter_basic_setting_screen.dart';
import 'base_setting_screen.dart';

class MobileSettingNavigationScreen extends BaseSettingScreen {
  const MobileSettingNavigationScreen({
    super.key,
    super.padding,
    super.showTitleBar,
    super.searchConfig,
    super.searchText,
  });

  static const String routeName = "/setting/navigation";

  @override
  State<MobileSettingNavigationScreen> createState() =>
      _MobileSettingNavigationScreenState();
}

class _MobileSettingNavigationScreenState
    extends BaseDynamicState<MobileSettingNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return ChewieItemBuilder.buildSettingScreen(
      context: context,
      title: appLocalizations.setting,
      showTitleBar: widget.showTitleBar,
      showBack: !ResponsiveUtil.isLandscapeLayout(),
      padding: widget.padding,
      children: [
        CaptionItem(
          context: context,
          title: appLocalizations.setting,
          children: [
            EntryItem(
              title: appLocalizations.generalSetting,
              leading: LoftifyIcons.generalSettings,
              showLeading: true,
              onTap: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  GeneralSettingScreen(key: generalSettingScreenKey),
                );
              },
            ),
            EntryItem(
              title: appLocalizations.appearanceSetting,
              leading: LoftifyIcons.appearance,
              showLeading: true,
              onTap: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  const AppearanceSettingScreen(),
                );
              },
            ),
            EntryItem(
              title: appLocalizations.imageSetting,
              leading: LoftifyIcons.image,
              showLeading: true,
              onTap: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  const ImageSettingScreen(),
                );
              },
            ),
            EntryItem(
              title: appLocalizations.lofterBasicSetting,
              leading: LoftifyIcons.basicSettings,
              showLeading: true,
              onTap: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  const LofterBasicSettingScreen(),
                );
              },
            ),
            EntryItem(
              title: appLocalizations.experimentSetting,
              leading: LoftifyIcons.experiment,
              showLeading: true,
              onTap: () {
                RouteUtil.pushCupertinoRoute(
                  context,
                  const ExperimentSettingScreen(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
